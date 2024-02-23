package main

import (
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
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
		return nil
	})
}
