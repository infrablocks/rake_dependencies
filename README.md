# RakeDependencies

Rake tasks for managing binary dependencies used within a build.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rake_dependencies'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rake_dependencies

## Usage

RakeDependencies provides a suite of tasklibs for downloading and extracting a
distribution of some dependency. The simplest way to configure all of these
tasks is via the `RakeDependencies::Tasks::All` tasklib. The following provides
an example usage with terraform as the target dependency:

```ruby
RakeDependencies::Tasks::All.new do |t|
  t.namespace = :terraform
  t.dependency = 'terraform'
  t.version = '0.9.0'
  t.path = File.join('vendor', 'terraform')
  t.type = :zip
  
  t.os_ids = {mac: 'darwin', linux: 'linux'}
  
  t.uri_template = 
      'https://releases.hashicorp.com/terraform/<%= @version %>/' +
          'terraform_<%= @version %>_<%= @os_id %>_amd64<%= @ext %>'
  t.file_name_template = 
      'terraform_<%= @version %>_<%= @os_id %>_amd64<%= @ext %>'
  
  t.needs_fetch = lambda do |parameters|
    terraform_binary = File.join(
        parameters[:path], parameters[:binary_directory], 'terraform')
    
    !(File.exist?(terraform_binary) &&
      `#{terraform_binary} -version`.lines.first =~ /#{parameters[:version]}/)
  end
end
```

With this in place, a number of tasks will be defined:
```bash
> rake -T
rake terraform:clean     # Clean vendored terraform
rake terraform:download  # Download terraform distribution
rake terraform:ensure    # Ensure terraform present
rake terraform:extract   # Extract terraform archive
rake terraform:fetch     # Fetch terraform
```

The tasks perform the following:
* `<ns>:clean` - recursively deletes the directory containing the dependency
* `<ns>:download` - downloads the distribution from the provided path into the
  dependency directory
* `<ns>:extract` - extracts, in the case of a compressed archive, or copies, in
  the case of an uncompressed distribution, the binaries into the binary 
  directory under the dependency directory
* `<ns>:fetch` - downloads then extracts
* `<ns>:ensure` - checks whether the dependency needs to be fetched and cleans
  and fetches if necessary

With these tasks defined, any task that requires the dependency to be present 
should depend on `<ns>:ensure`. Continuing the terraform example:
 
```ruby
task :provision_database => ['terraform:ensure'] do
  sh('vendor/terraform/bin/terraform apply infra/database')
end
```

The `RakeDependencies::Tasks::All` tasklib supports the following configuration
parameters:

| Name                          | Description                                                                                                           | Default                          | Required |
|-------------------------------|-----------------------------------------------------------------------------------------------------------------------|----------------------------------|:--------:|
| `namespace`                   | The namespace in which to define the tasks                                                                            | -                                | no       |
| `dependency`                  | The name of the dependency, used in status reporting                                                                  | -                                | yes      |
| `version`                     | The version of the dependency to manage, only required if used in templates or `needs_fetch`                          | -                                | no       |
| `path`                        | The path in which to install the dependency                                                                           | -                                | yes      |
| `type`                        | The archive type of the distribution, one of `:zip`, `:tar_gz`, `:tgz` or `:uncompressed`                             | `:zip`                           | yes      |
| `os_ids`                      | A map of platforms to OS identifiers to use in templates, containing entries for `:mac` and `:linux`                  | `{:mac: 'mac', :linux: 'linux'}` | yes      |
| `distribution_directory`      | The name of the directory under the supplied path into which to download the distribution                             | `'dist'`                         | yes      |
| `binary_directory`            | The name of the directory under the supplied path into which to extract/copy the binaries                             | `'bin'`                          | yes      |
| `uri_template`                | A template for the URI of the distribution                                                                            | -                                | yes      |
| `file_name_template`          | A template for the name of the downloaded file                                                                        | -                                | yes      |
| `target_name_template`        | A template for the name of the binary after extraction/copying                                                        | -                                | no       |
| `strip_path_template`         | A template for the path to strip within an archive before extracting                                                  | -                                | no       |
| `needs_fetch`                 | A lambda taking a parameter map that should return `true` if the dependency needs to be fetched, `false` otherwise    | Will always return `true`        | no       |
| `clean_task_name`             | The name of the clean task, required if it should be different from the default                                       | `:clean`                         | yes      |
| `download_task_name`          | The name of the download task, required if it should be different from the default                                    | `:download`                      | yes      |
| `extract_task_name`           | The name of the extract task, required if it should be different from the default                                     | `:extract`                       | yes      |
| `fetch_task_name`             | The name of the fetch task, required if it should be different from the default                                       | `:fetch`                         | yes      |
| `ensure_task_name`            | The name of the ensure task, required if it should be different from the default                                      | `:ensure`                        | yes      |

Notes:
* Each of the templates will have the following instance variables in scope when
  rendered:
  * `@version`: the supplied version string
  * `@platform`: the platform on which the task is executing, on of `:mac` or 
    `:linux`
  * `@os_id`: the OS identifier derived from the platform on which the task is 
    executing and the provided `os_ids` map
  * `@ext`: the file extension corresponding to the provided `type`, one of
    `.zip`, `.tar.gz`, `.tgz` or empty string for uncompressed files
* The `needs_fetch` lambda will receive a map with the following entries:
  * `path`: the supplied path
  * `version`: the supplied version string
  * `binary_directory`: the supplied or default binary directory
  
The `RakeDependencies::Tasks::All` tasklib uses each of the following tasklibs
in its definition:
* `RakeDependencies::Tasks::Clean`
* `RakeDependencies::Tasks::Download`
* `RakeDependencies::Tasks::Extract`
* `RakeDependencies::Tasks::Fetch`
* `RakeDependencies::Tasks::Ensure`

### `RakeDependencies::Tasks::Clean`

The `RakeDependencies::Tasks::Clean` tasklib supports the following 
configuration parameters:

| Name         | Description                                                               | Default                          | Required |
|--------------|---------------------------------------------------------------------------|----------------------------------|:--------:|
| `name`       | The name of the task, required if it should be different from the default | `:clean`                         | yes      |
| `path`       | The path in which the dependency is installed                             | -                                | yes      |
| `dependency` | The name of the dependency, used in status reporting                      | -                                | yes      |

### `RakeDependencies::Tasks::Download`

The `RakeDependencies::Tasks::Download` tasklib supports the following 
configuration parameters:

| Name                     | Description                                                                                          | Default                          | Required |
|--------------------------|------------------------------------------------------------------------------------------------------|----------------------------------|:--------:|
| `name`                   | The name of the task, required if it should be different from the default                            | `:download`                      | yes      |
| `dependency`             | The name of the dependency, used in status reporting                                                 | -                                | yes      |
| `version`                | The version of the dependency to manage, only required if used in templates                          | -                                | no       |
| `path`                   | The path in which to install the dependency                                                          | -                                | yes      |
| `type`                   | The archive type of the distribution, one of `:zip`, `:tar_gz`, `:tgz` or `:uncompressed`            | `:zip`                           | yes      |
| `os_ids`                 | A map of platforms to OS identifiers to use in templates, containing entries for `:mac` and `:linux` | `{:mac: 'mac', :linux: 'linux'}` | yes      |
| `distribution_directory` | The name of the directory under the supplied path into which to download the distribution            | `'dist'`                         | yes      |
| `uri_template`           | A template for the URI of the distribution                                                           | -                                | yes      |
| `file_name_template`     | A template for the name of the downloaded file                                                       | -                                | yes      |

Notes:
* The templates have the same instance variables in scope when rendered as 
  mentioned above.

### `RakeDependencies::Tasks::Extract`

The `RakeDependencies::Tasks::Extract` tasklib supports the following 
configuration parameters:

| Name                     | Description                                                                                          | Default                            | Required |
|--------------------------|------------------------------------------------------------------------------------------------------|------------------------------------|:--------:|
| `name`                   | The name of the task, required if it should be different from the default                            | `:extract`                         | yes      |
| `dependency`             | The name of the dependency, used in status reporting                                                 | -                                  | yes      |
| `version`                | The version of the dependency to manage, only required if used in templates                          | -                                  | no       |
| `path`                   | The path in which to install the dependency                                                          | -                                  | yes      |
| `type`                   | The archive type of the distribution, one of `:zip`, `:tar_gz`, `:tgz` or `:uncompressed`            | `:zip`                             | yes      |
| `os_ids`                 | A map of platforms to OS identifiers to use in templates, containing entries for `:mac` and `:linux` | `{:mac: 'mac', :linux: 'linux'}`   | yes      |
| `extractors`             | A map of archive types to extractor classes, see notes for further details                           | Extractors for all supported types | yes      |
| `distribution_directory` | The name of the directory under the supplied path into which the distribution was downloaded         | `'dist'`                           | yes      |
| `binary_directory`       | The name of the directory under the supplied path into which to extract/copy the binaries            | `'bin'`                            | yes      |
| `file_name_template`     | A template for the name of the downloaded file                                                       | -                                  | yes      |
| `target_name_template`   | A template for the name to give the binary after extraction/copying                                  | -                                  | no       |
| `strip_path_template`    | A template for the path to strip within an archive before extracting                                 | -                                  | no       |

Notes:
* The templates have the same instance variables in scope when rendered as 
  mentioned above.
* The extractors map has entries for the following keys:
  * `:zip`: An extractor class for zip files
  * `:tar_gz`: An extractor class for tar.gz files
  * `:tgz`: An alias for `:tar_gz` using the same extractor class
  * `:uncompressed`: An extractor class that copies the source to the 
    destination
* The extractor map can be overridden but should include entries for all of the
  above.

### `RakeDependencies::Tasks::Fetch`

The `RakeDependencies::Tasks::Fetch` tasklib supports the following 
configuration parameters:

| Name                | Description                                                               | Default                        | Required |
|---------------------|---------------------------------------------------------------------------|--------------------------------|:--------:|
| `name`              | The name of the task, required if it should be different from the default | `:fetch`                       | yes      |
| `dependency`        | The name of the dependency, used in status reporting                      | -                              | yes      |
| `download_task`     | The full name including namespaces of the download task                   | `<current-namespace>:download` | yes      |
| `extract_task`      | The full name including namespaces of the extract task                    | `<current-namespace>:extract`  | yes      |

### `RakeDependencies::Tasks::Ensure`

The `RakeDependencies::Tasks::Fetch` tasklib supports the following 
configuration parameters:

| Name               | Description                                                                                                           | Default                        | Required |
|--------------------|-----------------------------------------------------------------------------------------------------------------------|--------------------------------|:--------:|
| `name`             | The name of the task, required if it should be different from the default                                             | `:fetch`                       | yes      |
| `dependency`       | The name of the dependency, used in status reporting                                                                  | -                              | yes      |
| `version`          | The version of the dependency to manage, only required if used in templates                                           | -                              | no       |
| `path`             | The path in which to install the dependency                                                                           | -                              | yes      |
| `binary_directory` | The name of the directory under the supplied path into which to extract/copy the binaries                             | `'bin'`                        | yes      |
| `needs_fetch`      | A lambda taking a parameter map that should return `true` if the dependency needs to be fetched, `false` otherwise    | Will always return `true`      | no       |
| `clean_task`       | The full name including namespaces of the clean task                                                                  | `<current-namespace>:clean`    | yes      |
| `download_task`    | The full name including namespaces of the download task                                                               | `<current-namespace>:download` | yes      |
| `extract_task`     | The full name including namespaces of the extract task                                                                | `<current-namespace>:extract`  | yes      |

Notes:
* The templates have the same instance variables in scope when rendered as 
  mentioned above.
* The needs_fetch method receives the same parameter map as mentioned above.
  
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, 
run `rake spec` to run the tests. You can also run `bin/console` for an 
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at 
https://github.com/tobyclemson/rake_dependencies. This project is intended to
be a safe, welcoming space for collaboration, and contributors are expected to
adhere to the [Contributor Covenant](http://contributor-covenant.org) code of
conduct.


## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
