# Ubiquity::Mediasilo::Api::V3

A Library and Utilities to Interact with the MediaSilo API v3

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ubiquity-mediasilo-api-v3'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ubiquity-mediasilo-api-v3

## MediaSilo API V3 Executable [bin/ubiquity-mediasilo-api-v3](./bin/ubiquity-mediasilo-api-v3)
An executable to interact with the MediaSilo API

### Usage
    Usage:

        ubiquity-mediasilo-api-v3 -h | --help
        ubiquity-mediasilo-api-v3 --hostname <HOSTNAME> --username <USERNAME> --password <PASSWORD> --method-name <METHOD NAME> --method-arguments <JSON>

    Options:
            --hostname HOSTNAME          The hostname to authenticate with.
            --username USERNAME          The username to authenticate with.
            --password PASSWORD          The password to authenticate with.
            --method-name METHODNAME     The name of the method to call.
            --method-arguments JSON      The arguments to pass when calling the method.
            --pretty-print               Will format the output to be more human readable.
            --[no-]options-file [FILENAME]
                                         Path to a file which contains default command line arguments.
                                          default: ~/.options/ubiquity-mediasilo-api-v3
        -h, --help                       Display this message.


#### Examples

##### [Assets](http://developers.mediasilo.com/assets)

###### Asset Copy to Folder

###### Asset Copy to Project

###### Asset Create ([Create a new asset](http://developers.mediasilo.com/assets))

    ubiquity-mediasilo-api-v3 --hostname <HOSTNAME> --username <USERNAME> --password <PASSWORD> --method-name asset_create --method-arguments '{"project_id":"<PROJECT ID (GUID)>","source_url":"<SOURCE URL"}'

    - project_id [String] (Required) The ID of the Project this asset belongs to.
    - folder_id [String] The ID of the Folder this asset belongs to.
    - title [String] Defaults to filename
    - description [String] A brief description of the asset
    - source_url [String] Must be a publicly-accessible URL. NOTE: ** SPACES MUST BE REPLACED WITH a plus '+'
    - is_private [Boolean] If set to true, only authorized users can view the asset (this value may be overridden by account settings)

###### Asset Delete

    ubiquity-mediasilo-api-v3 --hostname <HOSTNAME> --username <USERNAME> --password <PASSWORD> --method-name asset_create --method-arguments '{"asset_id":"<ASSET ID (GUID)>"}'

    - asset_id [String] (Required) The id of the asset to delete.

##### Projects

###### Project Create ([Create a project](http://developers.mediasilo.com/projects)])

    ubiquity-mediasilo-api-v3 --hostname <HOSTNAME> --username <USERNAME> --password <PASSWORD> --method-name project_create --method-arguments '{"name":"<PROJECT NAME>"}'

    - name [String] (Required) Name of the project.
    - description [String] Description of the project.

###### Project Delete ([Delete a project](http://developers.mediasilo.com/projects)])

    ubiquity-mediasilo-api-v3 --hostname <HOSTNAME> --username <USERNAME> --password <PASSWORD> --method-name project_delete --method-arguments '{"id":"<PROJECT ID (GUID)>"}'

    - project_id [String] (Required) The id of the project to delete.

###### Project Get by Id ([Retrieve a project](http://developers.mediasilo.com/projects))

    ubiquity-mediasilo-api-v3 --hostname <HOSTNAME> --username <USERNAME> --password <PASSWORD> --method-name project_get_by_id --method-arguments '{"id":"<PROJECT ID (GUID)>"}'

    - id [String] (Required) Id (GUID) of the project.



## Contributing

1. Fork it ( https://github.com/XPlatform-Consulting/ubiquity-mediasilo-api-v3/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request



