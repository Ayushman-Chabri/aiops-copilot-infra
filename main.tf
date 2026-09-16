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
