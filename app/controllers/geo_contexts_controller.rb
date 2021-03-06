require 'RMagick'
require 'open-uri'
class GeoContextsController < ApplicationController
  before_filter :set_layout
  skip_before_filter :set_bc
  load_and_authorize_resource
  before_filter :set_bc
  include Magick
  

  def print_img

    #final_img = params[:tiles].inject(nil) do |img, tile|
    #  tile_img = image_from_params(tile.last)
    #  opacity = ((tile.last[:opacity].to_f - 100 ).abs / 100)
    #  #tile_img.opacity = opacity #(((tile.last[:opacity].to_f ).abs / 100) * Magick::TransparentOpacity ).to_i #unless !tile_img.opaque?
    #  if img.nil?
    #    img = tile_img
    #  else
    #  img = img.composite(tile_img, 0, 0, Magick::OverCompositeOp)
    #  #img = img.dissolve( tile_img, opacity, 1.0)
    #  end
    #  img
    #end
    
    i = ::Magick::ImageList.new
    params[:tiles].inject(nil) do |img, tile|
      tile_img = image_from_params(tile.last) 
      i << tile_img
    end
    final_img = i.flatten_images

    final_img.crop!(params[:x].to_i.abs, params[:y].to_i.abs, params[:width].to_i, params[:height].to_i)
    file_name = File.join("wmcs","#{Time.now.to_i}.png")
    name = File.join(Rails.root, "public", file_name)
    final_img.write(name)
    render :text => file_name 
  end

  def image_from_params(params)
    img = ::Magick::Image.from_blob(open(params[:url]).read)
    img.first
  end

  def external
    @geo_context = GeoContext.find(params[:id])
    #return render :text => "Not available" unless @geo_context.published
    render :layout => 'external'
  end


  def permalink
    @wmc = REDIS.get(params[:key])
    @wmc = Nokogiri::XML::Document.parse(@wmc)
    doc = @wmc
    if params[:single_tile]
      doc.xpath("//xmlns:Extension/ol:singleTile", doc.namespaces.merge('ol' => 'http://openlayers.org/context')).each do |l|
        l.content = true
      end
    end
      doc.xpath("//xmlns:Layer", doc.namespaces.merge('ol' => 'http://openlayers.org/context')).each do |l|
        l['queryable'] = "1"
      end
    @wmc = doc.to_xml
    render :xml => @wmc
  end

  def download
    @wmc = REDIS.get(params[:key])
    send_data @wmc, :filename => params[:name] << '.wmc'
  end

  def load
    str =  request.body.read
    id = save_context(str)
    render :json => {:success => true, :content => id}
  end

  def post
    id = save_context(params[:wmc])
    render :text => id
  end  

  def permalink_map
    @geo_context = GeoContext.find(params[:id])
    render :layout => false
    headers["Content-Type"] = "text/javascript"
  end

  # GET /geo_contexts
  # GET /geo_contexts.json

  def index
    @geo_contexts = GeoContext.page(page)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @geo_contexts }
    end
  end

  # GET /geo_contexts/1
  # GET /geo_contexts/1.json
  def show
    @show_infos = true
    set_seo(@geo_context) 
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @geo_context }
    end
  end

  private

  def set_layout
    #self.class.layout('application') if action_name == "show"
  end

  def save_context(wmc)
    if(session[:wmc] == nil)
      uuid = UUID.new
      id = uuid.generate
    else
      id = session[:wmc]
    end
    REDIS.set(id, wmc)
    return id
  end

  def set_bc
    super
    add_breadcrumb "Projets", nil
    add_breadcrumb @geo_context.group.try(:name), @geo_context.group if @geo_context.try(:group)
  end
end
