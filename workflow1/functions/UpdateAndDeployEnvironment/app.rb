require 'net/http'
require 'uri'
require 'logger'
require 'json'
require 'aws-sdk-ssm'

PROJECT     = ENV['PROJECT']
ENVIRONMENT = ENV['ENVIRONMENT']   

VAPOR_API_BASE           = 'https://vapor.laravel.com'
VAPOR_API_TOKEN_LOCATION = ENV['VAPOR_API_TOKEN_LOCATION']

HEADERS = {
  'Accept': 'application/json',
  'Content-Type': 'application/json'
}

$ssm = Aws::SSM::Client.new(region: ENV['AWS_REGION'])

$uri = URI.parse(VAPOR_API_BASE)
$http = Net::HTTP.new($uri.host, $uri.port)
$http.use_ssl = true

$logger = Logger.new($stdout)

def lambda_handler(event:, context:)
  resp = $ssm.get_parameter({
    name: VAPOR_API_TOKEN_LOCATION,
    with_decryption: true,
  })

  HEADERS[:Authorization] = 'Bearer ' + resp.parameter.value
  
  $logger.info('Get the environment variables for the given environment.')
  env_vars = get_env_vars()['variables']
  $logger.info('API completed.')

  to_update = {
    DB_WRITE: event['Endpoint'],
    DB_READ: event['ReaderEndpoint']
  }
  
  to_update.each { |k,v| env_vars = env_vars.gsub(/#{k}=.*/, "#{k}=#{v}") }
  
  $logger.info('Update the environment variables for the given environment.')
  put_env_vars(env_vars)
  $logger.info('API completed.')

  $logger.info("Redeploy the given environment's latest deployment.")
  deployment_id = post_redeployments()['id']
  $logger.info('API completed.')

  $logger.info('Wait until deployment is finished.')
  
  retries     = 0
  max_retries = 30
  interval    = 10

  begin
    deployment_status = get_deployments(deployment_id)['status']
    case deployment_status
    when 'finished'
      $logger.info("Deployment #{deployment_id} is finished.")
    else
      $logger.info("Deployment #{deployment_id} is in #{deployment_status}.")
      raise 'NotReady'
    end
  rescue => e
    retries += 1
    raise e if retries >= max_retries
    $logger.info("Wait #{interval} seconds and retry.")
    sleep interval
    retry
  end
end

def with_retry
  retries     ||= 0
  max_retries ||= 3
  interval    ||= 60

  begin
    resp = yield
    case resp
    when Net::HTTPTooManyRequests
      $logger.warn('Too Many Attempts: HTTP requests.')
      raise 'Too Many Attempts.'
    when Net::HTTPUnauthorized
      retries = max_retries
      raise 'HTTPUnauthorized.'
    else
      resp
    end
  rescue => e
    retries += 1
    raise e if retries >= max_retries
    $logger.warn("Wait #{interval} seconds and retry.")
    sleep interval
    retry
  end
end

def get_env_vars() 
  JSON.parse( with_retry { $http.request(Net::HTTP::Get.new($uri.path + "/api/projects/#{PROJECT}/environments/#{ENVIRONMENT}/variables", HEADERS)) }.body )
end

def put_env_vars(variables)
  req = Net::HTTP::Put.new($uri.path + "/api/projects/#{PROJECT}/environments/#{ENVIRONMENT}/variables", HEADERS) 
  req.body = { variables: variables }.to_json
  with_retry { $http.request(req) }
end

def post_redeployments()
  req = Net::HTTP::Post.new($uri.path + "/api/projects/#{PROJECT}/environments/#{ENVIRONMENT}/redeployments", HEADERS) 
  JSON.parse( with_retry { $http.request(req) }.body )
end

def get_deployments(deployment_id) 
  JSON.parse( with_retry { $http.request(Net::HTTP::Get.new($uri.path + "/api/deployments/#{deployment_id}", HEADERS)) }.body )
end
