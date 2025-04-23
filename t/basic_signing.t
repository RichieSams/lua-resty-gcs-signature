use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== Test Unsigned-Payload:
--- main_config
env GCS_ACCESS_KEY=XXXXX;
env GCS_SECRET_KEY=YYYYY;

--- config
    location = /t {
        content_by_lua_block {
            local gcs = require('resty.gcs-signature')

            -- Calculate the headers and stuff them into the response
            h = gcs.gcs_signed_headers_detailed('example.com', '/foo/bar', 'UNSIGNED-PAYLOAD', 1732156539)
            for k, v in pairs(h) do
                ngx.header[k] = v
            end

            ngx.print('ok')
        }
    }
--- request
GET /t
--- response_body chomp
ok
--- no_error_log
[error]
--- response_headers
Authorization: GOOG4-HMAC-SHA256 Credential=XXXXX/20241121/auto/storage/goog4_request,SignedHeaders=host;x-goog-content-sha256;x-goog-date,Signature=528346f587a0b46433f92d583f3148b88a5117bf26131f328553789feb433028
Host: example.com
x-goog-date: 20241121T023539Z
x-goog-content-sha256: UNSIGNED-PAYLOAD


=== Test Signed-Payload:
--- main_config
env GCS_ACCESS_KEY=XXXXX;
env GCS_SECRET_KEY=YYYYY;

--- config
    location = /t {
        content_by_lua_block {
            local gcs = require('resty.gcs-signature')

            -- Calculate the headers and stuff them into the response
            h = gcs.gcs_signed_headers_detailed('example.com', '/foo/bar', 'b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c', 1732156539)
            for k, v in pairs(h) do
                ngx.header[k] = v
            end

            ngx.print('ok')
        }
    }
--- request
GET /t
--- response_body chomp
ok
--- no_error_log
[error]
--- response_headers
Authorization: GOOG4-HMAC-SHA256 Credential=XXXXX/20241121/auto/storage/goog4_request,SignedHeaders=host;x-goog-content-sha256;x-goog-date,Signature=c5de427ece20baa9c60a3dca384aec3468a136e97a8adb2b75c7686dc9e4d589
Host: example.com
x-goog-date: 20241121T023539Z
x-goog-content-sha256: b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c
