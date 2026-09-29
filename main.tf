terraform{
    required_providers{
        aws={
            source="hashicorp/aws"
            version="~> 5.0"
        }
    }
    backend "s3"{
        bucket="aiops-copilot-tfstate-ayushh"
        key="aiops-copilot/terraform.tfstate"
        region="ap-south-1"
        encrypt=true
        use_lockfile=true
    }
}

provider "aws"{
    region="ap-south-1"
}

resource "aws_s3_bucket" "terraform_state"{
    bucket="aiops-copilot-tfstate-ayushh"


lifecycle{
    prevent_destroy=true
}
}

resource "aws_vpc""main"{
    cidr_block= "10.0.0.0/16"
    enable_dns_support=true
    enable_dns_hostnames=true

    tags={
        Name="aiops-copilot-vpc"
    }
}

resource "aws_subnet""public_a"{
    vpc_id=aws_vpc.main.id
    cidr_block="10.0.1.0/24"
    availability_zone="ap-south-1a"
    map_public_ip_on_launch=true

    tags={
        Name="aiops-copilot-public-a"
    }
}

resource "aws_subnet""public_b"{
    vpc_id=aws_vpc.main.id
    cidr_block="10.0.2.0/24"
    availability_zone="ap-south-1b"
    map_public_ip_on_launch=true

    tags={
        Name="aiops-copilot-public-b"
    }
}

resource "aws_internet_gateway""main"{
    vpc_id=aws_vpc.main.id

    tags={
        Name="aiops-copilot-igw"
    }
}

resource "aws_route_table""public"{
    vpc_id=aws_vpc.main.id
    route{
        cidr_block="0.0.0.0/0"
        gateway_id=aws_internet_gateway.main.id
    }

    tags={
        Name="aiops-copilot-public-rt"
    }
}

resource "aws_route_table_association""public_a"{
    subnet_id=aws_subnet.public_a.id
    route_table_id=aws_route_table.public.id
}

resource "aws_route_table_association""public_b"{
    subnet_id=aws_subnet.public_b.id
    route_table_id=aws_route_table.public.id
}

resource "aws_security_group" "k3s"{
    name_prefix= "aiops-copilot-k3s-"
    vpc_id=aws_vpc.main.id

    ingress{
        description="SSH"
        from_port=22
        to_port=22
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"]
    }

    ingress{
        description="Kubernetes API"
        from_port=6443
        to_port=6443
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"]
    }

    egress{
        from_port=0
        to_port=0
        protocol="-1"
        cidr_blocks=["0.0.0.0/0"]
    }

    tags={
        Name= "aiops-copilot-k3s-sg"
    }
}

resource "aws_instance""k3s_node"{
    ami="ami-0f5ee92e2d63afc18"
    instance_type="t3.micro"
    subnet_id=aws_subnet.public_a.id
    vpc_security_group_ids=[aws_security_group.k3s.id]
    key_name=aws_key_pair.k3s_key.key_name

    tags={
        Name="aiops-copilot-k3s-node"
    }
}

resource "aws_key_pair" "k3s_key"{
    key_name="aiops-copilot-k3s-key"
    public_key=file("${path.module}/aiops-copilot-key.pub")
}
