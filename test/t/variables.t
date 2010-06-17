# vi:filetype=perl

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(2);

plan tests => repeat_each() * (blocks() * 3 + 2 * 1 - 3 * 2);

worker_connections(128);
run_tests();

no_diff();

__DATA__

=== TEST 1: sanity
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select 'test' as echo";
        postgres_set        $test 0 0;
        add_header          "X-Test" $test;
    }
--- request
GET /postgres
--- error_code: 200
--- response_headers
Content-Type: application/x-resty-dbd-stream
X-Test: test
--- response_body eval
"\x{00}".        # endian
"\x{03}\x{00}\x{00}\x{00}".  # format version 0.0.3
"\x{00}".        # result type
"\x{00}\x{00}".  # std errcode
"\x{02}\x{00}".  # driver errcode
"\x{00}\x{00}".  # driver errstr len
"".              # driver errstr data
"\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}".  # rows affected
"\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}".  # insert id
"\x{01}\x{00}".  # col count
"\x{00}\x{80}".  # std col type (unknown/str)
"\x{c1}\x{02}".  # driver col type
"\x{04}\x{00}".  # col name len
"echo".          # col name data
"\x{01}".        # valid row flag
"\x{04}\x{00}\x{00}\x{00}".  # field len
"test".          # field data
"\x{00}"         # row list terminator
--- timeout: 10



=== TEST 2: out-of-range value (optional)
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select 'test' as echo";
        postgres_set        $test 0 1;
        add_header          "X-Test" $test;
    }
--- request
GET /postgres
--- error_code: 200
--- response_headers
Content-Type: application/x-resty-dbd-stream
X-Test:
--- timeout: 10



=== TEST 3: NULL value (optional)
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select NULL as echo";
        postgres_set        $test 0 0;
        add_header          "X-Test" $test;
    }
--- request
GET /postgres
--- error_code: 200
--- response_headers
Content-Type: application/x-resty-dbd-stream
X-Test:
--- timeout: 10



=== TEST 4: zero-length value (optional)
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select '' as echo";
        postgres_set        $test 0 0;
        add_header          "X-Test" $test;
    }
--- request
GET /postgres
--- error_code: 200
--- response_headers
Content-Type: application/x-resty-dbd-stream
X-Test:
--- timeout: 10



=== TEST 5: out-of-range value (required)
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select 'test' as echo";
        postgres_set        $test 0 1 required;
        add_header          "X-Test" $test;
    }
--- request
GET /postgres
--- error_code: 500
--- timeout: 10



=== TEST 6: NULL value (required)
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select NULL as echo";
        postgres_set        $test 0 0 required;
        add_header          "X-Test" $test;
    }
--- request
GET /postgres
--- error_code: 500
--- timeout: 10



=== TEST 7: zero-length value (required)
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select '' as echo";
        postgres_set        $test 0 0 required;
        add_header          "X-Test" $test;
    }
--- request
GET /postgres
--- error_code: 500
--- timeout: 10



=== TEST 8: $postgres_column_count
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select 'a', 'b', 'c'";
        add_header          "X-Columns" $postgres_column_count;
    }
--- request
GET /postgres
--- error_code: 200
--- response_headers
Content-Type: application/x-resty-dbd-stream
X-Columns: 3
--- timeout: 10



=== TEST 9: $postgres_row_count
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select 'a', 'b', 'c'";
        add_header          "X-Rows" $postgres_row_count;
    }
--- request
GET /postgres
--- error_code: 200
--- response_headers
Content-Type: application/x-resty-dbd-stream
X-Rows: 1
--- timeout: 10



=== TEST 10: $postgres_value (used with get_value)
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select 'test' as echo";
        postgres_get_value  0 0;
        add_header          "X-Value" $postgres_value;
    }
--- request
GET /postgres
--- error_code: 200
--- response_headers
Content-Type: text/plain
X-Value: test
--- response_body eval
"test"
--- timeout: 10



=== TEST 11: $postgres_value (used without get_value)
little-endian systems only

--- http_config
    upstream database {
        postgres_server     127.0.0.1 dbname=test user=monty password=some_pass;
    }
--- config
    location /postgres {
        postgres_pass       database;
        postgres_query      "select 'test' as echo";
        add_header          "X-Value" $postgres_value;
    }
--- request
GET /postgres
--- error_code: 200
--- response_headers
Content-Type: application/x-resty-dbd-stream
X-Value:
--- timeout: 10