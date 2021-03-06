class BookController < ApplicationController
  use Rack::Flash
#index
  get "/books" do
    set_user
    @books = Book.all
    erb :"books/index"
  end

#add books
  get "/books/new" do
    set_user
    erb :"books/new"
  end

  post "/books" do
    set_user
    @book = Book.find_or_initialize_by(name: params["name"])
    if @book.id
      if !@book.users.include?(current_user)
        @book.users << current_user
        @book.save
      end
      redirect to "/books/#{@book.slug}"
      # only update values if the current user is the owner_id
    else
      # finish adding book attributes and set an owner
      @book.owner = current_user
      @book.users << current_user
      @book.genre = Genre.find_or_create_by(name: params["genre"])
      @book.author = Author.find_or_create_by(name: params["author"])
      @book.save
      redirect to "/books/#{@book.slug}"
    end
  end

#show book
  get "/books/:slug" do
    set_user
    @book = Book.find_by_slug(params["slug"])
    if @book
      erb :"/books/show"
    else
      flash[:message] = "Book not found"
      redirect to "/books"
    end
  end

#button to add existing book to current user's library
  get "/books/:slug/add" do
    set_user
    @book = Book.find_by_slug(params[:slug])
    @user.books << @book
    redirect to "/users/#{@user.slug}"
  end

#edit a book
  get "/books/:slug/edit" do
    set_user
    @book = Book.find_by_slug(params[:slug])
    if @book && @book.owner == current_user
      erb :'books/edit'
    else
      if !@book
        flash[:message] = "Book not found."
        redirect to "/books"
      else
        flash[:message] = "Action not permitted."
        redirect to "/books"
      end
    end
  end

  patch "/books/:slug" do
    set_user
    @book = Book.find_by_slug(params[:slug])
    if @book && @book.owner == current_user
      author = Author.find_or_create_by(name: params[:author])
      genre = Genre.find_or_create_by(name: params[:genre])
      @book.update(author: author, genre: genre)
      redirect to "/books/#{@book.slug}"
    end
    redirect to "/books"
  end

  delete "/books/:slug" do
    set_user
    @book = Book.find_by_slug(params[:slug])
    if @book && @book.owner == current_user
      if @book.author.books.length == 1
        @book.author.delete
      end
      if @book.genre.books.length == 1
        @book.genre.delete
      else
        @book.author_id = nil
        @book.genre_id = nil
      end
      @book.delete
      redirect to "/books/index"
    else
      redirect to "/books/index"
    end
  end

  private
  def current_user
    if logged_in?
      User.find(session[:user_id])
    end
  end

  def set_user
    if logged_in?
      @user = current_user
    else
      flash[:message] = "Please sign up or login first."
      redirect to "/"
    end
  end
end
