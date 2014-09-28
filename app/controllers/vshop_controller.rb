#encoding:utf-8
class VshopController < ApplicationController

  layout "vshop"

  def new
    @account = Ecstore::Account.new
  end

  def login

  end

  def register

  end

  def user

    if @user

      @supplier =Ecstore::Supplier.find(params[:id])
      render :layout=>@supplier.layout
    else
      redirect_to "/mlogin?id=#{params[:id]}&platform=mobile&return_url=/vshop/#{params[:id]}/user?id=#{params[:id]}"
    end
  end

  def apply
    if params[:id]
      @supplier  =  Ecstore::Supplier.find(params[:id])
      @action_url =  "/admin/suppliers/#{params[:id]}?return_url=/vshop/apply"
      @method = :put
    end
  end

  #get /vshop/orders
  def orders

    if @user

      @orders_nw =Ecstore::Order.where(:supplier_id=> @user.account.supplier_id).order("order_id desc")

      if params[:status].nil?
        @orders_nw = @orders_nw
      elsif
      @orders_nw = @orders_nw.where(:status=>params[:status])
      end

      if !params[:pay_status].nil?
        @orders_nw = @orders_nw.where(:pay_status=>params[:pay_status])
      end

      if !params[:ship_status].nil?
        @orders_nw = @orders_nw.where(:ship_status=>params[:ship_status])
      end

      @order_ids = @orders_nw.pluck(:order_id)


      @orders = @orders_nw.includes(:user).paginate(:page=>params[:page],:per_page=>30)
      respond_to do |format|
        format.js
        format.html
      end

    else
      redirect_to '/vshop/login'
    end
  end

  #get /vshop/members
  def members
    if @user
      @supplier = Ecstore::Supplier.where(:member_id=>@user.id,:status=>1).first
      if @supplier
        @total_member = Ecstore::Account.where(:supplier_id=>@supplier.id).count()
        @accounts = Ecstore::Account.where(:supplier_id=>@supplier.id).paginate(:page => params[:page], :per_page => 20).order("account_id DESC")
        #@column_data = YAML.load(File.open(Rails.root.to_s+"/config/columns/member.yml"))
        respond_to do |format|
          format.html # index.html.erb
          format.json { render json: @members }
        end
      else
        redirect_to '/vshop/apply'
      end
    else
      redirect_to '/vshop/login'
    end
  end

  #get /vshop/weixin
  def weixin
    if @user
      @supplier = Ecstore::Supplier.where(:member_id=>@user.account.id).first
      @action = "/admin/suppliers/#{@supplier.id}?return_url=/vshop/weixn"
      render  :layout=>'vshop_wechat'
    else
      redirect_to '/vshop/login'
    end
  end

  #get /vshop/goods
  def goods
    if @user
      @goods = Ecstore::Good.includes(:cat).includes(:brand)

      if @user.id!= 2495 #贸威
        @supplier =Ecstore::Supplier.find_by_member_id(@user.id)
        @goods = @goods.where(:supplier_id=>@supplier.id)
      end

      @goods = @goods .paginate(:page=>params[:page],:per_page=>20,:order => 'uptime DESC')   #分页

      @count = @goods.count
    else
      redirect_to '/vshop/login'
    end
  end

  def article
    @article = Ecstore::Page.includes(:meta_seo).find(params[:id])
  end

  def create
    now  = Time.now
    @account = Ecstore::Account.new(params[:user]) do |ac|
      ac.account_type ="member"
      ac.createtime = now.to_i
      ac.user.member_lv_id = 1
      ac.user.cur = "CNY"
      ac.user.reg_ip = request.remote_ip
      ac.user.regtime = now.to_i
    end

    if @account.save
      sign_in(@account)
      @return_url=params[:return_url]
      render "create"
    else
      render "error"
    end
  end

  def search
    @title = "找回密码"
    @by = params[:user][:by]
    value = params[:user][:value]
    col =  case @by
             when 'mobile' then '手机号码'
             when 'email' then '邮箱'
             when 'login_name' then '用户名'
             else '用户名'
           end
    if value.present?
      @user = Ecstore::User.joins(:account).where("#{@by} = ?",value).first
      if @user
        render "find_by_#{@by}"
      else
        redirect_to forgot_password_users_url(:by=>@by), :notice=> "您输入的#{col}不存在"
      end
    else
      redirect_to forgot_password_users_url(:by=>@by), :notice=> "请输入#{col}"
    end
  end

  #get /vhsop/id 显示微店铺首页
  def show
    @supplier_id=params[:id]
    @homepage = Ecstore::Home.where(:supplier_id=>@supplier_id).last
    @supplier = Ecstore::Supplier.find(@supplier_id)
    @good=Ecstore::Good.where(:supplier_id=>@supplier_id)
    render :layout=>@supplier.layout
  end

  #get /vhsop/id/category?cat=
  def category
    @supplier_id=params[:id]
    @cat = params[:cat]
    @goods =  Ecstore::Good.where(:supplier_id=>@supplier_id,:cat_id=>@cat)
    @supplier = Ecstore::Supplier.find(@supplier_id)
    render :layout=>"#{@supplier.layout}"
  end

  #get /vhsop/id/payments
  def payments
    supplier_id=params[:id]
    order_id = params[:order_id]
    @supplier = Ecstore::Supplier.find(supplier_id)

    @appId= @supplier.weixin_appid
    @timeStamp = Time.now.to_i      #时间戳
    @nonceStr = '' #随机串
    @packageValue ='' #扩展包
    @signType = "SHA1"  #微信签名方式:1.sha1
    @paySign = ''    #微信签名


  end

end
