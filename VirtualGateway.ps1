$URI = "https://ncrest.sdn-cloud.com"

# Create the tenant virtual gateway
# Create a new object for tenant virtual gateway
$VirtualNetwork = Get-NetworkControllerVirtualNetwork -ConnectionUri $uri
$VirtualNetwork.Properties.AddressSpace.AddressPrefixes += "10.254.254.0/24"

$VPNVirtualSubnet = new-object Microsoft.Windows.NetworkController.VirtualSubnet  
$VPNVirtualSubnet.ResourceId = "VPN"  
$VPNVirtualSubnet.Properties = new-object Microsoft.Windows.NetworkController.VirtualSubnetProperties  
$VPNVirtualSubnet.Properties.AccessControlList = $null 
$VPNVirtualSubnet.Properties.AddressPrefix = "10.254.254.0/24"  

$VirtualNetwork.Properties.Subnets += $VPNVirtualSubnet

New-NetworkControllerVirtualNetwork -ResourceId $VirtualNetwork.ResourceId -ConnectionUri $uri -properties $VirtualNetwork.properties

$VirtualNetworkSubnets = Get-NetworkControllerVirtualSubnet -ConnectionUri $uri -VirtualNetworkId $VirtualNetwork.ResourceId
$VirtualGWProperties = New-Object Microsoft.Windows.NetworkController.VirtualGatewayProperties 

# Specify the Virtual Subnet to use for routing between the gateway and virtual network 
$RoutingSubnet = Get-NetworkControllerVirtualSubnet -ConnectionUri $URI -VirtualNetworkId $VirtualNetwork.ResourceId -ResourceId $VirtualNetworkSubnets[2].ResourceId
$VirtualGWProperties.GatewaySubnets = @()
$VirtualGWProperties.GatewaySubnets += $RoutingSubnet

# Specify the virtual gateway resourceID
$VirtualGatewayId = "Tenant-01_GW"

# Update gateway pool reference
$gwPool = Get-NetworkControllerGatewayPool -ConnectionUri $URI -ResourceId "Default"
$VirtualGWProperties.GatewayPools = @()
$VirtualGWProperties.GatewayPools += $gwPool

# Update the rest of the virtual gateway object properties
$VirtualGWProperties.RoutingType = "Dynamic"
$VirtualGWProperties.NetworkConnections = @()
$VirtualGWProperties.BgpRouters = @()

New-NetworkControllerVirtualGateway -ConnectionUri $uri -ResourceId $VirtualGatewayId -Properties $VirtualGWProperties
$VirtualGW = Get-NetworkControllerVirtualGateway -ConnectionUri $uri -ResourceId $VirtualGatewayId

# Create the tenant BGP router
# Create a new object for the tenant BGP router
$bgpRouterproperties = New-Object Microsoft.Windows.NetworkController.VGwBgpRouterProperties 

# Update the BGP router properties
$bgpRouterproperties.ExtAsNumber = "0.65001" 
$bgpRouterproperties.RouterId = "10.254.254.2" 
$bgpRouterproperties.RouterIP = @("10.254.254.2") 
$BGPRouter_ResourceId = "Tenant-01_Vnet_Router1"

# Add the new BGP router for the tenant
New-NetworkControllerVirtualGatewayBgpRouter -ConnectionUri $URI -VirtualGatewayId $VirtualGatewayId -ResourceId $BGPRouter_ResourceId -Properties $bgpRouterProperties -Force
$bgpRouter = Get-NetworkControllerVirtualGatewayBgpRouter -ConnectionUri $URI -VirtualGatewayId $VirtualGatewayId -ResourceId $BGPRouter_ResourceId

# Create the tenant IPSec connection
# Create a new object for tenant network connection
$nwConnectionProperties = New-Object Microsoft.Windows.NetworkController.NetworkConnectionProperties

# Update the common object properties
$nwConnectionProperties.ConnectionType = "IPSec"
$nwConnectionProperties.OutboundKiloBitsPerSecond = 500
$nwConnectionProperties.InboundKiloBitsPerSecond = 500

# Update specific properties depending on the connection type
$nwConnectionProperties.IpSecConfiguration = New-Object Microsoft.Windows.NetworkController.IpSecConfiguration
$nwConnectionProperties.IpSecConfiguration.AuthenticationMethod = "PSK"
$nwConnectionProperties.IpSecConfiguration.SharedSecret = "P@ssw0rd"

# Configure IPSec

$nwConnectionProperties.IpSecConfiguration.QuickMode = New-Object Microsoft.Windows.NetworkController.QuickMode 
$nwConnectionProperties.IpSecConfiguration.QuickMode.PerfectForwardSecrecy = "PFS2"
$nwConnectionProperties.IpSecConfiguration.QuickMode.AuthenticationTransformationConstant = "SHA196"
$nwConnectionProperties.IpSecConfiguration.QuickMode.CipherTransformationConstant = "AES256" 
$nwConnectionProperties.IpSecConfiguration.QuickMode.SALifeTimeSeconds = 3600
$nwConnectionProperties.IpSecConfiguration.QuickMode.IdleDisconnectSeconds = 300
$nwConnectionProperties.IpSecConfiguration.QuickMode.SALifeTimeKiloBytes = 102400

$nwConnectionProperties.IpSecConfiguration.MainMode = New-Object Microsoft.Windows.NetworkController.MainMode 
$nwConnectionProperties.IpSecConfiguration.MainMode.DiffieHellmanGroup = "Group2" 
$nwConnectionProperties.IpSecConfiguration.MainMode.IntegrityAlgorithm = "SHA1" 
$nwConnectionProperties.IpSecConfiguration.MainMode.EncryptionAlgorithm = "AES256" 
$nwConnectionProperties.IpSecConfiguration.MainMode.SALifeTimeSeconds = 28800
$nwConnectionProperties.IpSecConfiguration.MainMode.SALifeTimeKiloBytes = 819200

# L3 specific configuration
$nwConnectionProperties.IPAddresses = @() 
$nwConnectionProperties.PeerIPAddresses = @() 

# Update the IPv4 routes that are reachable over the site-to-site VPN tunnel
$nwConnectionProperties.Routes = @() 
$ipv4Route = New-Object Microsoft.Windows.NetworkController.RouteInfo 
$ipv4Route.DestinationPrefix = "14.1.10.0/24" 
$ipv4Route.metric = 10 
$nwConnectionProperties.Routes += $ipv4Route 

# Tunnel destination (remote endpoint) address
$nwConnectionProperties.DestinationIPAddress = "100.10.10.101" 

# Add the new network connection for the tenant
New-NetworkControllerVirtualGatewayNetworkConnection -ConnectionUri $URI -VirtualGatewayId $VirtualGatewayId -ResourceId "IPSecGW" -Properties $nwConnectionProperties -Force

$VirtualGatewayNetworkConnection = Get-NetworkControllerVirtualGatewayNetworkConnection -ConnectionUri $uri -VirtualGatewayId $VirtualGatewayId

# Create a new object for tenant BGP peer
$bgpPeerProperties = New-Object Microsoft.Windows.NetworkController.VGwBgpPeerProperties 

# Update the BGP peer properties
$bgpPeerProperties.PeerIpAddress = "14.1.10.1" 
$bgpPeerProperties.AsNumber = 64521 
$bgpPeerProperties.ExtAsNumber = "0.64521" 

# Add the new BGP peer for tenant
New-NetworkControllerVirtualGatewayBgpPeer -ConnectionUri $uri -VirtualGatewayId $VirtualGatewayId -BgpRouterName $bgpRouter.ResourceId -ResourceId "IPSec_Peer" -Properties $bgpPeerProperties -Force
$VirtualGatewayBgpPeer = Get-NetworkControllerVirtualGatewayBgpPeer -ConnectionUri $URI -VirtualGatewayId $VirtualGatewayId -BgpRouterName $bgpRouter.ResourceId -ResourceId IPSec_Peer
