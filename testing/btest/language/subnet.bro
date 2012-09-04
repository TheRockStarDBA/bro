# @TEST-EXEC: bro %INPUT >out
# @TEST-EXEC: btest-diff out

function test_case(msg: string, expect: bool)
        {
        print fmt("%s (%s)", msg, expect ? "PASS" : "FAIL");
        }


# TODO: "subnet inequality" tests (i.e., tests with "!=") always fail 

event bro_init()
{
	# IPv4 addr
	local a1: addr = 192.1.2.3;

	# IPv4 subnets 
	local s1: subnet = 0.0.0.0/0;
	local s2: subnet = 192.0.0.0/8;
	local s3: subnet = 255.255.255.255/32;
	local s4 = 10.0.0.0/16;

	test_case( "IPv4 subnet equality", a1/8 == s2 );
	test_case( "IPv4 subnet inequality", a1/4 != s2 );
	test_case( "IPv4 subnet in operator", a1 in s2 );
	test_case( "IPv4 subnet !in operator", a1 !in s3 );
	test_case( "IPv4 subnet type inference", type_name(s4) == "subnet" );

	# IPv6 addrs
	local b1: addr = [ffff::];
	local b2: addr = [ffff::1];
	local b3: addr = [ffff:1::1];

	# IPv6 subnets
	local t1: subnet = [::]/0;
	local t2: subnet = [ffff::]/64;
	local t3 = [a::]/32;

	test_case( "IPv6 subnet equality", b1/64 == t2 );
	test_case( "IPv6 subnet inequality", b3/64 != t2 );
	test_case( "IPv6 subnet in operator", b2 in t2 );
	test_case( "IPv6 subnet !in operator", b3 !in t2 );
	test_case( "IPv6 subnet type inference", type_name(t3) == "subnet" );

	test_case( "IPv4 and IPv6 subnet inequality", s1 != t1 );
	test_case( "IPv4 address and IPv6 subnet", a1 !in t2 );

}

