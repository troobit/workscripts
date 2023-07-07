$pip = (Get-AzPublicIpAddress -ResourceGroupName "Cassandra" | select "ipaddress").ipaddress
ssh -i ~.ssh\cass01_key.pem azureuser@$pip

sudo yum update -y #update yum (package manager)

# Add the required repo and keys to install Cassandra
sudo tee -a /etc/yum.repos.d/cassandra.repo <<END
[cassandra]
name=Apache Cassandra
baseurl=https://www.apache.org/dist/cassandra/redhat/40x
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://www.apache.org/dist/cassandra/KEYS
enabled=1
END

#enable Microsoft repo's for installation, as well as the cass one we just made
sudo yum-config-manager --enable '*microsoft*'
sudo yum-config-manager --enable '*cassandra*'

sudo yum install -y cassandra #install (yum will manage dependencies)

#This is where cluster specific config will happen - by editing (or importing) the cassandra.yaml file. Here we're just renaming the cluster with sed (and RegEx, because... masochism).
sudo sed -i "s/cluster_name: 'Test Cluster'/cluster_name: 'PEGA_cass_cluster'/g" /etc/cassandra/conf/cassandra.yaml

#start 'er up!
sudo service cassandra start