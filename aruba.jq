def protocol_name(num):
  if num == "1" then "icmp"
  elif num == "6" then "tcp"
  elif num == "17" then "udp" 
  elif num == "*" then "ip"
  else num
  end;

def port_spec(port):
  if port == "*" then ""
  else " eq " + port
  end;

def ip_spec(ips; direction):
  if ips == ["*"] then "any"
  else ips | map(if . | contains("/32") then "host " + (. | split("/")[0]) else . end) | join(" ")
  end;

"# Aruba Switch ACL Configuration",
"# Generated from JSON firewall rules",
"",
"ip access-list extended WORKLOAD_INBOUND_ACL",
"",
(
  .[0].rules.Inbound[] as $rule | 
  range(0; ($rule.ips | length)) as $i |
  (($i * 10) + 10) as $seq |
  if $rule.protocol == "*" and $rule.port == "*" then
    ($seq | tostring) + " permit ip any any  # catch-all rule"
  else
    ($seq | tostring) + " " + $rule.action + " " + protocol_name($rule.protocol) + 
    " " + ip_spec([$rule.ips[$i]]; "source") + 
    " any" + port_spec($rule.port)
  end
),
"",
"ip access-list extended WORKLOAD_OUTBOUND_ACL", 
"",
(
  .[0].rules.Outbound[] as $rule |
  range(0; ($rule.ips | length)) as $i |
  (($i * 10) + 10) as $seq |
  if $rule.protocol == "*" and $rule.port == "*" then
    ($seq | tostring) + " permit ip any any  # catch-all rule"
  else
    ($seq | tostring) + " " + $rule.action + " " + protocol_name($rule.protocol) +
    " any " + ip_spec([$rule.ips[$i]]; "dest") + port_spec($rule.port)
  end
),
"",
"# Apply to VLAN interface",
"interface vlan 10",
" ip access-group WORKLOAD_INBOUND_ACL in",
" ip access-group WORKLOAD_OUTBOUND_ACL out"
