# frozen_string_literal: true

module RakeDependencies
  # rubocop:disable Naming/VariableNumber
  module PlatformNames
    CPU = {
      x86_64: 'amd64',
      x64: 'amd64',
      x86: '386',
      arm: 'arm',
      arm64: 'arm64'
    }.freeze
    OS = {
      darwin: 'darwin',
      linux: 'linux',
      mswin32: 'windows',
      mswin64: 'windows'
    }.freeze
  end
  # rubocop:enable Naming/VariableNumber
end
