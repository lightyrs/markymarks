class Reaper

  def initialize(options = {})
    raise ArgumentError unless @user = User.find(options[:user_id])
    @provider = Provider.find_by_id(options[:provider_id])
  end

  def harvest_links
    case @provider.try(:name)
    when 'Facebook'
      harvest_links_from_facebook
    when 'Twitter'
      harvest_links_from_twitter
    when 'Pocket'
      harvest_links_from_pocket
    else
      harvest_links_from_all_providers
    end
  end

  private

  def harvest_links_from_all_providers
    harvest_links_from_facebook
    harvest_links_from_twitter
    harvest_links_from_pocket
  end

  def harvest_links_from_facebook(links = nil, options = {})
    begin
      @graph ||= GraphClient.new(@user.token(provider_id: Provider.facebook.id))
      links ||= @graph.links
      links.each_with_index do |link, index|
        if index == (links.count - 1)
          next_links = links.next_page
          harvest_links_from_facebook(next_links) if next_links.present?
        else
          create_link_from_facebook(link)
        end
      end
    rescue => e
      puts "#{e.class}: #{e.message}".red
    end
  end

  def create_link_from_facebook(link)
    begin
      url = link['link']
      title = link['name']
      posted_at = DateTime.parse(link['created_time'])
      Link.delay_for(1.minute, retry: 2, queue: :normal_priority).process(url, title, "#{posted_at}", Provider.facebook.id, @user.id)
    rescue => e
      puts "#{e.class}: #{e.message}".red
    end
  end

  def harvest_links_from_twitter
    client = TwitterClient.new
    tweets = client.all_tweets(@user.username(provider_id: Provider.twitter.id))
    create_links_from_twitter(tweets.select(&:urls?))
  end

  def create_links_from_twitter(tweets)
    tweets.each do |tweet|
      begin
        links = tweet.urls.map(&:expanded_url).flatten.compact
        links.each do |link|
          begin
            url = "#{link}"
            posted_at = tweet.created_at
            Link.delay_for(1.minute, retry: 2, queue: :normal_priority).process(url, nil, posted_at, Provider.twitter.id, @user.id)
          rescue => e
            puts "#{e.class}: #{e.message}".red
          end
        end
      rescue => e
        puts "#{e.class}: #{e.message}".red
      end
    end
  end

  def harvest_links_from_pocket
    client = PocketClient.new(@user.token(provider_id: Provider.pocket.id))
    links = client.retrieve_list
    create_links_from_pocket(links)
  end

  def create_links_from_pocket(links)
    links.each do |item_id, link_hash|
      begin
        url = link_hash['resolved_url'] || link_hash['given_url']
        title = link_hash['given_title'] || link_hash['resolved_title']
        posted_at = DateTime.strptime(link_hash['time_added'], '%s')
        Link.delay_for(1.minute, retry: 2, queue: :normal_priority).process(url, title, posted_at, Provider.pocket.id, @user.id)
      rescue => e
        puts "Reaper#create_links_from_pocket: #{e.class}: #{e.message}".red
      end
    end
  end
end
