# $Id: http-request.bro 6726 2009-06-07 22:09:55Z vern $

# Analysis of HTTP requests.

@load http

module HTTP;

export {
	const sensitive_URIs =
		  /etc\/(passwd|shadow|netconfig)/
		| /IFS[ \t]*=/
		| /nph-test-cgi\?/
		| /(%0a|\.\.)\/(bin|etc|usr|tmp)/
		| /\/Admin_files\/order\.log/
		| /\/carbo\.dll/
		| /\/cgi-bin\/(phf|php\.cgi|test-cgi)/
		| /\/cgi-dos\/args\.bat/
		| /\/cgi-win\/uploader\.exe/
		| /\/search97\.vts/
		| /tk\.tgz/
		| /ownz/	# somewhat prone to false positives
		| /viewtopic\.php.*%.*\(.*\(/	# PHP attack, 26Nov04
		# a bunch of possible rootkits
		| /sshd\.(tar|tgz).*/
		| /[aA][dD][oO][rR][eE][bB][sS][dD].*/
		# | /[tT][aA][gG][gG][eE][dD].*/	# prone to FPs
		| /shv4\.(tar|tgz).*/
		| /lrk\.(tar|tgz).*/
		| /lyceum\.(tar|tgz).*/
		| /maxty\.(tar|tgz).*/
		| /rootII\.(tar|tgz).*/
		| /invader\.(tar|tgz).*/
	&redef;

	# Used to look for attempted password file fetches.
	const passwd_URI = /passwd/ &redef;

	# URIs that match sensitive_URIs but can be generated by worms,
	# and hence should not be flagged (because they're so common).
	const worm_URIs =
		  /.*\/c\+dir/
		| /.*cool.dll.*/
		| /.*Admin.dll.*Admin.dll.*/
	&redef;

	# URIs that should not be considered sensitive if accessed by
	# a local client.
	const skip_remote_sensitive_URIs =
		/\/cgi-bin\/(phf|php\.cgi|test-cgi)/
	&redef;

	const sensitive_post_URIs = /wwwroot|WWWROOT/ &redef;

	# Include the referrer header in the log.
	const log_referrer = F &redef;
}

redef capture_filters +=  {
	["http-request"] = "tcp dst port 80 or tcp dst port 8080 or tcp dst port 8000"
};

event http_request(c: connection, method: string, original_URI: string,
			unescaped_URI: string, version: string)
	{
	local log_it = F;
	local URI = unescaped_URI;

	if ( (sensitive_URIs in URI && URI != worm_URIs) ||
	     (method == "POST" && sensitive_post_URIs in URI) )
		{
		if ( is_local_addr(c$id$orig_h) &&
		     skip_remote_sensitive_URIs in URI )
			; # don't flag it after all
		else
			log_it = T;
		}

	local s = lookup_http_request_stream(c);

	if ( process_HTTP_replies )
		{
		# To process HTTP replies, we need to record the corresponding
		# requests.
		local n = s$first_pending_request + s$num_pending_requests;

		s$requests[n] = [$method=method, $URI=URI, $log_it=log_it,
					$passwd_req=passwd_URI in URI];
		++s$num_pending_requests;

		# if process_HTTP_messages
		local msg = s$next_request;

		init_http_message(msg);
		msg$initiated = T;
		}
	else
		{
		if ( log_it )
			NOTICE([$note=HTTP_SensitiveURI, $conn=c,
				$method = method, $URL = URI,
				$msg=fmt("%s %s: %s %s",
					id_string(c$id), c$addl, method, URI)]);
		print http_log,
			fmt("%.6f %s %s %s", network_time(), s$id, method, URI);
		}
	}
