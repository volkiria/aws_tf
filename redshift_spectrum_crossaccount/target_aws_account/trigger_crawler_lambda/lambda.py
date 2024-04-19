import boto3, json, re, os

def trigger_crawler(event, context):
    glue_client = boto3.client('glue')

    environment = os.environ['ENVIRONMENT']
    crawler_name_prefix = os.environ['CRAWLER_NAME_PREFIX']
    object_key = event['Records'][0]['s3']['object']['key']
    folder_pattern = re.compile('.*/$')
    if folder_pattern.match(object_key):
        print('Skip: Folder creation event')
        return {
          'statusCode': 200,
          'body': json.dumps('Done')
        }
    table_category = object_key.split('/')[0]
    crawler_name = '-'.join((crawler_name_prefix,table_category))
    check_crawler = glue_client.list_crawlers(Tags={'Name': crawler_name})
    if len(check_crawler["CrawlerNames"]) > 0:
        print('Triggering crawler: '+crawler_name)
        glue_client = boto3.client('glue')
        response = glue_client.start_crawler(Name=crawler_name)
    else:
        print('Skip: No such crawler - '+crawler_name+'; Table category \''+table_category+'\' is not supported')
    return {
      'statusCode': 200,
      'body': json.dumps('Done')
    }

