Add-VpnS2SInterface -Name IPSECtoKOALRA -Destination 41.40.40.3 -Protocol IKEv2 -AuthenticationMethod PSKOnly -SharedSecret "P@ssw0rd" `
 -IPv4Subnet "10.254.254.2/32:10" -AuthenticationTransformConstants SHA196 -CipherTransformConstants AES256 -DHGroup Group2 `
 -EncryptionMethod AES256 -IntegrityCheckMethod SHA1 -PfsGroup PFS2 -CustomPolicy

 Add-BgpPeer -Name CloudPeer -LocalIPAddress 14.1.10.1 -PeerIPAddress 10.254.254.2 -LocalASN 64521 -PeerASN 65001