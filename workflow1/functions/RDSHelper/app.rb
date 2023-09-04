require 'aws-sdk-rds'

$rds = Aws::RDS::Client.new(region: ENV['AWS_REGION'])

MAX_ATTEMPTS = 30
DELAY = 20

def lambda_handler(event:, context:)
  if event.key? 'DBInstanceIdentifier'
    params = { db_instance_identifier: event['DBInstanceIdentifier'] }
    $rds.wait_until(:db_instance_available, params) do |w|
      w.max_attempts = MAX_ATTEMPTS
      w.delay = DELAY
    end

  elsif event.key? 'DBClusterIdentifier'
    params = { db_cluster_identifier: event['DBClusterIdentifier'] }
    $rds.wait_until(:db_cluster_available, params) do |w|
      w.max_attempts = MAX_ATTEMPTS
      w.delay = DELAY
    end

  elsif event.key? 'DBClusterToDeletePrefix'
    rds_resources_to_delete(event['DBClusterToDeletePrefix'])
  end
end

def rds_resources_to_delete(db_cluster_identifier_prefix)
  resp = $rds.describe_db_clusters()
  db_clusters_list = resp.db_clusters.find_all do |db_cluster|
    db_cluster.db_cluster_identifier.start_with? db_cluster_identifier_prefix
  end

  return {} if db_clusters_list.size() <= 1
    
  db_cluster = (db_clusters_list.sort_by &:cluster_create_time).first

  {
    DBClusterIdentifier: db_cluster.db_cluster_identifier,
    DBClusterMembersIdentifiers: (db_cluster.db_cluster_members.map &:db_instance_identifier)
  }
end
