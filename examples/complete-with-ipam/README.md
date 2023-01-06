# Pre-requisites

1. Having the AWS Ipam configured in the AWS account with a pool named `dev`.

1. Document DB master credentials - Create a pair of `username` and `password` in JSON format like:

   ```json
   {
     "username": "my_username",
     "password": "my_password"
   }
   ```

   and upload it to **AWS Secrets Manager** in encrypted format.

   Update the local variable in `main.tf`:

   ```sh
    db_creds_secret_id = "your_secret_name"
   ```

1. Update all the necessary parameters passed to the various modules with your information.
