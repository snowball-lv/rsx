# rsx

A file hosting server for ShareX written in Ruby.

# Usage
- Create a `conf.rb` file as per [conf-example.rb](./conf-example.rb) to your liking:

```ruby
BASE_URL="yourdomain.com"
MAX_UPLOAD_MB=20
FILE_DIR="./files"
PASSWORD="your_password"
```

- And simply run:

```bash
./rsx.rb
```
# Notes

[rsx.rb](./rsx.rb#L18) assumes `https` when generating URLs.
