require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
INITIAL_PLAYER_AMOUNT = 500
DEALER_MIN_HIT = 17

helpers do
	def calculate_total(cards)
		arr = cards.map{|x| x[1]}

		total = 0
		arr.each do |c|
			if c == "Ace"
				total +=11
			else
				total += c.to_i == 0 ? 10 : c.to_i
			end
	end

	arr.select{|x| x == "Ace"}.count.times do
		break if total <= BLACKJACK_AMOUNT
			total -= 10
		end
		total
	end

	def dealer_hit(hand)
		if calculate_total(hand) < DEALER_MIN_HIT
			hand << session[:deck].pop
			@info = "Another card for ol' Bender..."
		end
	end

	def card_image(card)
		suit = case card[0]
			when 'Clubs' then 'clubs'
			when 'Spades' then 'spades'
			when 'Hearts' then 'hearts'
			when 'Diamonds' then 'diamonds'
		end
		value = card[1]
		if ['Jack', 'Queen', 'King', 'Ace'].include?(value)
			value = case card[1]
				when 'Jack' then 'jack'
				when 'Queen' then 'queen'
				when 'King' then 'king'
				when 'Ace' then 'ace'
			end
		end
			"<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
	end

	def winner!(msg)
    @play_again = true
    @end_game = false
    session[:player_money] = session[:player_money] + session[:player_bet]
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @end_game = false
    session[:player_money] = session[:player_money] - session[:player_bet]
    @error = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @end_game = false
    @info = "<strong>Tie!</strong> #{msg}"
  end
end



before do
	@any_money = true
	@end_game = false
	@dealer_show = false
end

get '/' do
	if session[:player_name]
		redirect '/game'
	else
		redirect '/new_player'
	end
end

get '/new_player' do
	session[:player_money] = INITIAL_PLAYER_AMOUNT
	erb :new_player
end

get '/bet' do
	session[:player_bet] = nil
	erb :bet
end

post '/bet' do
	if params[:bet_amount].to_i == 0 || params[:bet_amount].nil?
		@error = "Nice try, meatbag... Show me some money!"
		halt erb(:bet)
	elsif params[:bet_amount].to_i > session[:player_money]
		@error = "This isn't a charity! You can't bet more than you got!"
		halt erb(:bet)
	else
		session[:player_bet] = params[:bet_amount].to_i
		redirect '/game'
	end
end

post '/new_player' do
	if params[:player_name].empty?
		@error = "Gimme a name, meatbag!"
		halt erb(:new_player)
	end
	session[:player_name] = params[:player_name]
	redirect '/bet'
end

get '/game' do
	suits = ['Clubs','Spades','Hearts','Diamonds']
	values = ['2','3','4','5','6','7','8','9','10','Jack','Queen','King','Ace']
	session[:deck] = suits.product(values).shuffle!
	session[:dealer_cards] = []
	session[:player_cards] = []
	2.times do 
		session[:dealer_cards] << session[:deck].pop
		session[:player_cards] << session[:deck].pop
	end
	erb :game
end

post '/game/player/hit' do
	session[:player_cards] << session[:deck].pop
		dealer_hit(session[:dealer_cards])
	if calculate_total(session[:player_cards]) >= 21
		redirect '/end_game'
	else
		erb :game
	end
end


post '/game/player/stay' do
	dealer_hit(session[:dealer_cards])
	@success = "You have chosen to stay!"
	redirect '/end_game'
end

post '/game/restart' do
	redirect '/bet'
end

post '/game/different_player' do
	erb :new_player
end

post '/game/exit' do
	erb :exit
end

get '/end_game' do
	player = calculate_total(session[:player_cards])
	computer = calculate_total(session[:dealer_cards])
	if player > 21
		loser!("Looks like you busted, pal.")
	elsif player == 21 && computer == 21
		tie!("Both of us got Blackjack!")
	elsif player == 21 && computer != 21
		winner!("Dohh... Bite my shiny metal ass!")
	elsif player != 21 && computer == 21
	  loser!("In your face jerkwad! I got Blackjack! Sweet Somalians!")
	elsif player > 21 && computer <= 21
		loser!("You lose pal... OM! OM! Sweet legal tender!")
	elsif player <= 21 && computer > 21
		winner!("Dohh... I busted. I guess you win!")
	elsif player == computer
		tie!("It looks like it was a tie")
	elsif player > computer
		winner!("You win!")
	elsif player < computer
		loser!("You lose pal... OM! OM! Sweet legal tender!")
	else
		@info = "a strange situation..."
	end
	if session[:player_money] == 0
		@any_money = false
	end
	@dealer_show = true
	@end_game = true
	erb :game
end












