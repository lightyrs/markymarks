class GraphClient

  include ActiveModel::Model

  def initialize(oauth_access_token)
    @client = init_client(oauth_access_token)
  end

  def me
    @client.get_object('me') rescue nil
  end

  def feed
    @client.get_connections('me', 'feed') rescue nil
  end

  def links
    @client.get_connections('me', 'links') rescue nil
  end

  private

  def init_client(oauth_access_token)
    Koala::Facebook::API.new(oauth_access_token)
  end
end
