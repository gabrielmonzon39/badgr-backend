class BadgrController < ApplicationController
  require 'uri'
  require 'net/http'

  def get_badges
    badgr_token = generate_token
    url = URI("https://api.badgr.io/v2/issuers/#{Rails.application.credentials.badgr[:puntocrea_id]}/badgeclasses")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "Bearer #{badgr_token.token}"
    response = JSON.parse(https.request(request).read_body, object_class: OpenStruct)
    render json: list_badges(response.result)
  end

  def issue_badge
    badgr_token = generate_token
    url = URI("https://api.badgr.io/v2/badgeclasses/#{params[:badge_id]}/assertions")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request['Authorization'] = "Bearer #{badgr_token.token}"
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(
      recipient: {
        identity: params[:email].to_s,
        type: 'email',
        hashed: true
      },
      narrative: params[:narrative].to_s,
      expires: params[:expires].to_s,
      notify: true
    )
    response = JSON.parse(https.request(request).read_body, object_class: OpenStruct)
    render json: response
  end

  def get_issued_badges
    render json: get_issued_badges_list
  end

  def get_backpack
    backpack = get_issued_badges_list.select { |badge| OpenStruct.new(badge).recipient == params[:email] }
    render json: backpack
  end

  private

  def get_issued_badges_list
    badgr_token = generate_token
    url = URI("https://api.badgr.io/v2/issuers/#{Rails.application.credentials.badgr[:puntocrea_id]}/assertions")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "Bearer #{badgr_token.token}"
    response = JSON.parse(https.request(request).read_body, object_class: OpenStruct)
    list_issued_badges(response.result)
  end

  def list_badges(badge_list)
    badge_list.map do |badge|
      badge = OpenStruct.new(badge)
      BadgrBadge.find_or_create_by(
        class_name: badge.entityId,
        name: badge.name,
        description: badge.description,
        image: badge.image
      )
      {
        id: badge.entityId,
        name: badge.name,
        description: badge.description,
        image: badge.image
      }
    end
  end

  def list_issued_badges(badge_list)
    badge_list.map do |badge|
      badge = OpenStruct.new(badge)
      badge_details = BadgrBadge.find_by(class_name: badge.badgeclass)
      {
        id: badge.entityId,
        created_at: badge.createdAt,
        image: badge.image,
        badge_name: badge_details.name,
        badge_description: badge_details.description,
        verification_link: badge.openBadgeId,
        recipient: badge.recipient.plaintextIdentity
      }
    end
  end

  def generate_token_with_refresh_token
    badgr_token = BadgrToken.last

    url = URI('https://api.badgr.io/o/token')

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    form_data = [%w[grant_type refresh_token], ['refresh_token', badgr_token.refresh_token]]
    request.set_form form_data, 'multipart/form-data'
    response = JSON.parse(https.request(request).read_body)

    BadgrToken.create(
      token: response['access_token'],
      refresh_token: response['refresh_token'],
      expired_at: Time.now + response['expires_in'].to_i
    )
  end

  def generate_token_with_password
    email = Rails.application.credentials.badgr[:email]
    password = Rails.application.credentials.badgr[:password]

    url = URI('https://api.badgr.io/o/token')

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    form_data = [['username', email], ['password', password]]
    request.set_form form_data, 'multipart/form-data'
    response = JSON.parse(https.request(request).read_body)

    BadgrToken.create(
      token: response['access_token'],
      refresh_token: response['refresh_token'],
      expired_at: Time.now + response['expires_in'].to_i
    )
  end

  def generate_token
    badgr_token = BadgrToken.last
    if badgr_token.nil?
      badgr_token = generate_token_with_password
    elsif badgr_token.expired_at < Time.now
      badgr_token = generate_token_with_refresh_token
    end
    badgr_token
  end
end
