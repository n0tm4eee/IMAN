#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if user exists
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username, games_played) VALUES('$USERNAME', 0)"
else
  # Existing user
  IFS='|' read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate random number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Start the game
echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0

while true; do
  read GUESS
  ((GUESS_COUNT++))

  # Check if input is a number
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Compare guess
  if [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  elif [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Update user stats
    if [[ -z $USER_INFO ]]; then
      $PSQL "UPDATE users SET games_played = 1, best_game = $GUESS_COUNT WHERE username='$USERNAME'"
    else
      ((GAMES_PLAYED++))
      if [[ -z $BEST_GAME || $GUESS_COUNT -lt $BEST_GAME ]]; then
        $PSQL "UPDATE users SET best_game = $GUESS_COUNT WHERE username='$USERNAME'"
      fi
      $PSQL "UPDATE users SET games_played = $GAMES_PLAYED WHERE username='$USERNAME'"
    fi

    break
  fi
done
