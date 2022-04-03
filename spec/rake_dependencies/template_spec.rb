# frozen_string_literal: true

require 'spec_helper'

describe RakeDependencies::Template do
  it 'renders the provided template using the supplied variables' do
    expect(
      described_class
        .new('<%= @foo %> : <%= @bar %>, <%= @thing %>@<%= @do %>')
        .with_parameter('foo', 1234)
        .with_parameter('bar', 5678)
        .with_parameters(thing: 'thinger', do: 'doer')
        .render
    ).to eq('1234 : 5678, thinger@doer')
  end
end
