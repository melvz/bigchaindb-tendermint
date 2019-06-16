
## This is the actual working Terraform script that simply creates 1 BigchainDB and Tendermint node for playground.
##

variable "region" {
  default = "us-east-2"
}
variable "shared_credentials_file" {
  default = "~/.aws/credentials"
}

variable "profile" {
  default = "profile"
}

variable "count" {
  default=1
}


provider "aws" {
  region                  = "${var.region}"
  shared_credentials_file = "${var.shared_credentials_file}"
  profile                 = "${var.profile}"
}
resource "aws_instance" "web" {
  count="${var.count}"
  ami   = "${var.bigchaindb_ami}"
  instance_type = "t2.medium"
  key_name = "centaur"
  vpc_security_group_ids  = ["${aws_security_group.bigchaindb_server_sg.id}"]
  tags { Name = "${format("bigchain-tester-%01d",count.index+1)}" }
  associate_public_ip_address = "true"

  #TODO: script below is okay, just need to add more steps based on https://tendermint.com/docs/app-dev/getting-started.html#first-tendermint-app
  user_data = <<-EOF
          #! /bin/bash
          sudo apt update -y
          sudo apt install -y python3-pip libssl-dev
          sudo pip3 install pip==19.1.1
          sudo pip3 install bigchaindb==2.0.0b9
          sudo apt install mongodb -y
          sudo apt install -y unzip
          wget https://github.com/tendermint/tendermint/releases/download/v0.22.8/tendermint_0.22.8_linux_amd64.zip
          unzip tendermint_0.22.8_linux_amd64.zip
          rm tendermint_0.22.8_linux_amd64.zip
          sudo mv tendermint /usr/local/bin
          sleep 2
          sudo apt  install golang-go -y
          echo export GOPATH=\"\$HOME/go\" >> /home/ubuntu/.bash_profile
          echo export PATH=\"\$PATH:\$GOPATH/bin\" >> /home/ubuntu/.bash_profile
          source ~/.bash_profile
          mkdir -p $GOPATH/src/github.com/tendermint
          go get github.com/tendermint/tendermint
          EOF


  root_block_device {
    volume_type           = "standard"
    volume_size           = "30"
    delete_on_termination = "true"
  }
}
