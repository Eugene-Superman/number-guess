#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=postgres -t --no-align -c"
TABLE="number_guess"

echo "Enter your username:"
read INPUT_USERNAME

USER=$($PSQL "SELECT username, games_played, best_game, secret_number FROM $TABLE WHERE username = '$INPUT_USERNAME';")

if [[ -z "$USER" ]]; then
  NEW_USER_RESULT=$($PSQL "INSERT INTO $TABLE(username) VALUES('$INPUT_USERNAME') RETURNING *;")
  echo "Welcome, $INPUT_USERNAME! It looks like this is your first time here."
else
  IFS="|" read -r username games_played best_game secret_number <<< "$USER"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

SECRET_NUMBER=$($PSQL "UPDATE $TABLE SET secret_number = FLOOR(RANDOM() * (1000 - 1 + 1) + 1)::INTEGER WHERE username = '$INPUT_USERNAME' RETURNING secret_number;" | sed -n 's/^\([0-9]*\).*/\1/p')

ATTEMPS=0

COMPARE_NUMBERS() {
  ATTEMPS=$(($ATTEMPS + 1))
  if [ "$SECRET_NUMBER" -eq $1 ]; then
    if [[ "$best_game" -eq 0 || "$ATTEMPS" -lt "$best_game" ]]; then
      BEST_GAME_RESULT=$($PSQL "UPDATE $TABLE SET best_game = $ATTEMPS WHERE username = '$INPUT_USERNAME';")
    fi
    GAMES_PLAYED_RESULT=$($PSQL "UPDATE $TABLE SET games_played = games_played + 1 WHERE username = '$INPUT_USERNAME';")
    echo "You guessed it in $ATTEMPS tries. The secret number was $SECRET_NUMBER. Nice job!"
    exit 0
  else
    if [ "$SECRET_NUMBER" -lt $1 ]; then
      REQUEST_UNSWER "It's lower than that, guess again:"
    else
      REQUEST_UNSWER "It's higher than that, guess again:"
    fi
  fi
}

REQUEST_UNSWER() {
  echo "$1"
  read INPUT_NUMBER

  if [[ "$INPUT_NUMBER" =~ ^-?[0-9]+$ ]]; then
    COMPARE_NUMBERS $INPUT_NUMBER
  else
    REQUEST_UNSWER "That is not an integer, guess again:"
  fi

}

REQUEST_UNSWER "Guess the secret number between 1 and 1000:"
