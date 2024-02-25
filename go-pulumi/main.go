package main

import (
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"github.com/pulumi/pulumi-awsx/sdk/v2/go/awsx/ec2"
	//"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2" 
	"github.com/joho/godotenv"
	"fmt"
	"log"
	"os"
)



func main() {
	// Attempt to load .env file and exit if it doesn't exist
	err := godotenv.Load()
	if err != nil {
	  log.Fatal("Error loading .env file")
	}

	// Assign .env values
	dns := os.Getenv("DNS_HOSTNAME")
	fmt.Println(dns)
	pocket_account_pw := os.Getenv("POCKET_ACCOUNT_PASSWORD")
	fmt.Println(pocket_account_pw)

	pulumi.Run(func(ctx *pulumi.Context) error {
		// Create a new VPC 
		vpc, err := ec2.NewVpc(ctx, "vpc", &ec2.VpcArgs{
			CidrBlock: pulumi.StringRef("172.16.0.0/16"),
		})
		if err != nil {
			return err
		}

		// Export VPC properties for use in EC2
		ctx.Export("vpcId", vpc.VpcId)
		ctx.Export("privateSubnetIds", vpc.PrivateSubnetIds)
		ctx.Export("publicSubnetIds", vpc.PublicSubnetIds)

		// Create required security group 
		sg, err := ec2.NewSec
		
		// Build EC2 instance in public subnets 

		return nil
	})
}
