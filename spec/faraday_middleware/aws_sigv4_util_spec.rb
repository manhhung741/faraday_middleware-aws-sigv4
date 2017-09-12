RSpec.describe FaradayMiddleware::AwsSigV4Util do
  let(:class_with_util) do
    Class.new do
      include FaradayMiddleware::AwsSigV4Util
    end
  end

  describe '#normalize_for_net_http!' do
    let(:env) { OpenStruct.new(request_headers: {}) }

    subject do
      class_with_util.new.normalize_for_net_http!(env)
      env.request_headers
    end

    context 'have zlib' do
      before do
        stub_const('Net::HTTP::HAVE_ZLIB', true)
      end

      it {
        is_expected.to match(
          'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3')
      }
    end

    context 'have no zlib' do
      before do
        stub_const('Net::HTTP::HAVE_ZLIB', false)
      end

      it { is_expected.to match('Accept' => '*/*') }
    end
  end

  describe '#seahorse_encode_query' do
    subject do
      class_with_util.new.seahorse_encode_query(url).query
    end

    context 'with query' do
      let(:url) do
        URI.parse('http://example.com/hello?foo=b+a+r&bar=z+o+o&bar=baz&baz&&zoo=baz')
      end

      it { is_expected.to eq 'foo=b%20a%20r&bar=z%20o%20o&bar=baz&baz=&=&zoo=baz' }
    end

    context 'without query' do
      let(:url) do
        URI.parse('http://example.com/hello')
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#seahorse_encode_www_form' do
    subject do
      class_with_util.new.seahorse_encode_www_form(params).split(?&)
    end

    context 'not include space' do
      let(:params) do
        [
          ['foo', 'bar'],
          ['bar', ['zoo', 'baz']],
          ['baz', nil],
          ['zoo', [nil, 'baz']],
        ]
      end

      it { is_expected.to match_array URI.encode_www_form(params).split(?&) }
    end

    context 'include space' do
      let(:params) do
        [
          ['foo', 'b a r'],
          ['bar', ['z o o', 'baz']],
          ['baz', nil],
          ['zoo', [nil, 'baz']],
        ]
      end

      it { is_expected.to match_array URI.encode_www_form(params).gsub(?+, '%20').split(?&) }
    end
  end
end
