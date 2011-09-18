gem   'haml'
run   'rm public/index.html'

route "match '/*page' => 'pages#show'"
route "root :to => 'pages#show', :page => 'home'"
route "get  'login'  => 'sessions#new',     :as => 'login'"
route "get  'logout' => 'sessions#destroy', :as => 'logout'"
route "post 'logout' => 'sessions#destroy', :as => 'logout'"
route "get  'signup' => 'users#new',        :as => 'signup'"
route "resources :users"
route "resources :sessions"

generate :model, 'user', 'email:string', 'password_digest:string'
run  'rm app/models/user.rb'
file 'app/models/user.rb', <<-EOF
class User < ActiveRecord::Base
  has_secure_password
  attr_accessible :email, :password, :password_confirmation
  validates :password, :presence => { :on => :create }, :confirmation => true 
  validates :email,    :presence => true, :uniqueness => true
end
EOF

generate :controller, 'users'
run  'rm app/controllers/users_controller.rb'
file 'app/controllers/users_controller.rb', <<-EOF
class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      redirect_to root_url, :notice => 'Updated.'  
    else
      render :edit
    end
  end

  def create
    @user = User.new(params[:user])  
    if @user.save  
      redirect_to root_url, :notice => 'Created.'  
    else  
      render 'new'  
    end 
  end
end
EOF

generate :controller, 'sessions'
run  'rm app/controllers/sessions_controller.rb'
file 'app/controllers/sessions_controller.rb', <<-EOF
class SessionsController < ApplicationController
  def new
  end

  def create
    if (user = User.find_by_email(params[:email])) && user.authenticate(params[:password]) 
      session[:user_id] = user.id
      redirect_to session[:next_page] || root_url, :notice => 'Logged in.'
    else
      flash.now.alert = 'Invalid email or password'
      render 'new'
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, :notice => 'Logged out.'  
  end
end
EOF

generate :controller, 'pages'
run  'rm app/controllers/pages_controller.rb'
file 'app/controllers/pages_controller.rb', <<-EOF
class PagesController < ApplicationController
  def show
    render "/pages/\#{params[:page]}"
  end
end
EOF

file 'app/views/sessions/new.haml', <<-EOF
= form_tag sessions_path do
  = label_tag :email 
  = text_field_tag :email, params[:email]
  = label_tag :password
  = password_field_tag :password
  = submit_tag
EOF

file 'app/views/users/new.haml', <<-EOF
= form_for @user || User.new(params[:user]) do |f|
  = f.label      :email
  = f.text_field :email
  = f.label      :password
  = f.password_field :password
  = f.label      :password_confirmation
  = f.password_field :password_confirmation
  = submit_tag
EOF

rake 'db:migrate'
