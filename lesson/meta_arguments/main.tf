resource aws_s3_bucket "bucket1" {

  count=2  
  bucket = var.bucket_name[count.index]

  tags = var.resource_tags
}

resource aws_s3_bucket "bucket2"{
    for_each=var.bucket_name_set

    bucket = each.key
    tags = var.resource_tags
    depends_on = [ aws_s3_bucket.bucket1 ]
}