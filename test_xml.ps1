[xml]$StorageFragment='<storage>
 <source>"http://source"</source>
 <destin>"http://destin"</destin>
</storage>’
 
$xml = [xml](Get-Content .\sub_config.xml)
$node = $xml.Azure.CloudServices.ChildNodes[0]
$node.appendChild($xml.ImportNode($StorageFragment.storage,$true)) 

$newkey = $xml.CreateElement("storage")
$newkey.SetAttribute("source","http://source")
$newkey.SetAttribute("destin","http://destin")

$xml.Azure.CloudServices.ChildNodes[0].Servers.AzureVM[0].AppendChild($newkey)
#or
$node = $xml.Azure.CloudServices.ChildNodes[0].Servers.AzureVM[0]
$node.AppendChild($newkey)
$xml.Save("D:\GitHub\AzureReDeployKit\x.xml")

###
$newRole = $xml.CreateElement("Role")
$xml.Data.Roles.AppendChild($newRole)

$newRole.SetAttribute(“Name”,”ADServer”);
$newRole.SetAttribute(“Value”,”NewADServer”);


####
 
# Get XML Document Object from String 
[xml]$oConfig2Merge='<config description="Users"> 
  <customers> 
    <user surname="Campbell" firstname="Wayne">Wayne</user> 
    <user surname="Garth" firstname="Algar">Garth</user> 
    <user surname="Cheers" firstname="Phil">Phil</user> 
  </customers> 
</config>' 

 Migrate the customers node to our config file defined at the top of the post 

# Get the target config Node 
$oXMLConfigTarget=$oConfig2Merge.selectSingleNode("config") 
# Get the Node which is to migrate 
$oXMLCustomers=$oConfig2Merge.config.customers 
# or 
$oXMLCustomers=$oConfig2Merge.selectSingleNode("config/customers") 
# Import the Node with the ImportNode Function from System.XML.XMLDocument 
$oXMLConfigTarget.appendChild($oXMLDocument.ImportNode($oXMLCustomers,$true)) 
$oXMLDocument.Save("c:\temp\config.xml") 
