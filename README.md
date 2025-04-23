# lua-resty-aws-signature

This library is a fork of the [lua-resty-aws-signature](https://github.com/jobteaser/lua-resty-aws-signature). It adapts the code and methods for use with Google Storage Buckets

## Overview

This library implements request signing using the [Google Signature
Version 4](https://cloud.google.com/storage/docs/access-control/signed-urls) specification. This signature scheme is used for GCS access.

## Usage

This library uses GCS environment variables as credentials to generate signed request headers.

```bash
export GCS_ACCESS_KEY=AKIDEXAMPLE
export GCS_SECRET_KEY=AKIDEXAMPLE
```

To be accessible in your nginx configuration, these variables should be declared in your `nginx.conf` file. Example:

```nginx
worker_processes  1;

error_log  /dev/fd/1 debug;

env GCS_ACCESS_KEY;
env GCS_SECRET_KEY;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    access_log  /dev/stdout;

    include /etc/nginx/conf.d/*.conf;
}
```

You can then use the library to calculate the GCS Signature headers and `proxy_pass` to GCS.

NOTE: gcs_signed_headers*() returns a table of headers you should apply to the request. It does *not* set them for you. This allows you to use the same function when doing LUA-only HTTP calls with something like [ledgetech/lua-resty-http](https://github.com/ledgetech/lua-resty-http).

```nginx
set $s3_host my_bucket.storage.googleapis.com;
set $region us-west-1;
set $service s3

location / {
  access_by_lua_block {
    local aws = require('resty.aws-signature')

    local headers = aws.gcs_signed_headers(ngx.var.s3_host, ngx.var.uri, ngx.var.region, ngx.var.service, ngx.var.request_body)
    for k, v in pairs(h) do
      ngx.req.set_header(k, v)
    end
  }

  proxy_pass https://$s3_host;
}
```

Here's an example of doing a subrequest with `ledgetech/lua-resty-http`

```nginx
set $s3_host my_bucket.s3-eu-west-1.amazonaws.com;
set $region us-west-1;
set $service s3

location / {
  content_by_lua_block {
    local aws = require('resty.aws-signature')
    local http = require("resty.http")

    local headers = aws.aws_signed_headers_unsigned_payload(ngx.var.s3_host, '/my/path/to/thing', ngx.var.region, ngx.var.service, 'My custom body')

    local http_client = http.new()
    local res, err = http_client:request_uri('https://' .. ngx.var.s3_host .. '/my/path/to/thing', {
      method = "GET",
      headers = headers
    })

    if res == nil then
      ngx.status = 500
      ngx.say('Upstream request failed')
      return
    end

    ngx.status = res.status
    for k, v in pairs(res.headers) do
        ngx.header[k] = v
    end
    ngx.say(res.body)
  }
}
```

The default AWS Signature V4 setup requires that you hash the entire request body, and include that hash as part of the signature calculation. This adds an extra layer of protection, because it means the body of the request can't be tampered with in transit, otherwise the signature will be invalid.

However, this hashing does come with a cost: namely you have to buffer and read the entire request body. If you don't want to pay this cost, you can use the `aws_signed_headers_unsigned_payload()` instead. This utilizes the [`UNSIGNED-PAYLOAD`](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html) signing option, which allows us to skip reading / hashing the request body.

```nginx
set $s3_host my_bucket.s3-eu-west-1.amazonaws.com;
set $region us-west-1;
set $service s3

location / {
  access_by_lua_block {
    local aws = require('resty.aws-signature')

    local headers = aws.aws_signed_headers_unsigned_payload(ngx.var.s3_host, ngx.var.uri, ngx.var.region, ngx.var.service)
    for k, v in pairs(h) do
      ngx.req.set_header(k, v)
    end
  }

  proxy_pass https://$s3_host;
}
```

## Contributing

Check [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## License

Copyright 2024 Adrian Astley (RichieSams)

Copyright 2018 JobTeaser

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
