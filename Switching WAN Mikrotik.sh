# Settings
:local myip "0.0.0.0";

# Determine the total number of netwatch rules enabled with the specified source address
:local NetWatchCountAll [/tool/netwatch/print count-only where src-address=$myip disabled=no];

# Determine the number of rules in the status UP
:local NetWatchCountUp [/tool/netwatch/print count-only where src-address=$myip disabled=no status=up];

# Determine the number of rules in the status Down
:local NetWatchCountDown [/tool/netwatch/print count-only where src-address=$myip disabled=no status=down];

:local RtStatus [/ip route get [find comment="RT"] disable];
:local KesStatus [/ip route get [find comment="KES"] disable];

#A stub check, in case someone enables or removes all the rules from netwatch:
:if ($NetWatchCountAll = 0) do={
    :log info "No active checks netwatch"
# Stop the script execution
    :error
}

#If the number of netwatch rules is equal to the number of rules in the down status then:
:if (($NetWatchCountAll = $NetWatchCountDown) && ($KesStatus=true)) do={
    /ip route disable [find comment="RT"];
    # Enabling a route via KES
    /ip route enable [find comment="KES"];
    # Remove all TCP and UDP connections.
    /ip firewall connection remove [ find protocol~"tcp" ];
    /ip firewall connection remove [ find protocol~"udp" ];
    :delay 1000ms;
    :log info "RT crash switching to KES"
}

# If the number of netwatch rules with the up status is greater than zero then:
:if (($NetWatchCountUp > 0) && ($RtStatus=true)) do={
     # Enabling a route via RT
    /ip route enable [find comment="RT"]
     # Disabling route via KES
    /ip route disable [find comment="KES"]
    # Remove all TCP and UDP connections.
    /ip firewall connection remove [ find protocol~"tcp" ];
    /ip firewall connection remove [ find protocol~"udp" ];
    :delay 1000ms;
    :log info "RT restored, routes switched"
}