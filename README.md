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

# ShareX

Use the following custom uploader settings:

- Method `POST`
- Request URL  `https://yourdomain.com/upload`
- Body `Form data (multipart/form-data)`
- URL Parameters
    - Name `password`, Value `your_password`
- File from name `img`

# Frontend

You can view uploads using the following endpoints:

- `/album` - uploads made by your IP
- `/album/all`- uploads made by all IPs

# Notes

- [rsx.rb](./rsx.rb#L48) assumes `https` when generating URLs
- requires `imagemagick` to be installed
