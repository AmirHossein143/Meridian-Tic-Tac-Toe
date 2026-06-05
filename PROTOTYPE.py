
import math
import tkinter as tk
from tkinter import simpledialog, messagebox

def create_board(size):
    return [[' ' for i in range(size)] for i in range(size)]

def board_is_full(board): #if board is full it returns true if not it returns false and the game continues
    return all(cell != ' ' for row in board for cell in row)

def count_streak(board, x, y, dx, dy, player): #counts streaks in a given direction
    count = 0
    size = len(board)
    while 0 <= x < size and 0 <= y < size and board[x][y] == player:
        count += 1
        x += dx
        y += dy
    return count

def evaluate_board(board): #for calculating the score of every given board either it's ai or the player
    ai_score = 0
    human_score = 0
    size = len(board)
    scores = {'O': 0, 'X': 0}
    directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
    for i in range(size):
        for j in range(size):
            if board[i][j] in scores:  #if the position blongs to X or O its true
                player = board[i][j]
                for dx, dy in directions: 
                    count = count_streak(board, i, j, dx, dy, player)
                    if count >= 3:
                        scores[player] += 1 + (count - 3)  #1point for 3 in a row, n-3 for longer
                        score = 1 + (count - 3)  
                        if player == 'O': #for calculating the end of the game
                            ai_score += score
                        else:
                            human_score += score
    return scores['O'] - scores['X'], human_score, ai_score,

def get_empty_squares(board): #returns a list of all available moves
    available_moves = []
    for i in range(len(board)): 
        for j in range(len(board)):
            if board[i][j] == ' ':
                available_moves.append((i, j))
    return available_moves

def minimax(board, depth, alpha, beta, maximizing, memory):  
    #alpha is the best value maximizing player can get and beta for the minimizing player
    #maximizing is True if AI is playing and False if human is playing
    board_state = []
    for row in board:
        board_state.append(tuple(row))
    key = tuple(board_state)
    #print(key)
    if key in memory:
        return memory[key]
    if depth == 0 or board_is_full(board):
        score = evaluate_board(board)[0]
        memory[key] = score
        return score
    best_score = -math.inf if maximizing else math.inf
    moves = get_empty_squares(board)
    player = 'O' if maximizing else 'X'
    
    for i, j in moves:
        board[i][j] = player
        score = minimax(board, depth - 1, alpha, beta, not maximizing, memory)
        board[i][j] = ' '
        if maximizing == True:
            best_score = max(best_score, score)
            alpha = max(alpha, best_score) #stores the best score for ai
        else:
            best_score = min(best_score, score) 
            beta = min(beta, best_score) #stores the best score for player
        if beta <= alpha:
            break
    memory[key] = best_score
    return best_score

def best_move(board):
    best_score = -math.inf
    move = (-1, -1)
    memory = {}
    empty_count = len(get_empty_squares(board))
    min_depth, max_depth = 0, 0
    #a method for making ai smarter the thurther you go
    if empty_count <= 16: min_depth, max_depth = 4, 6
    elif empty_count <= 24: min_depth, max_depth = 3, 5
    elif empty_count <= 60: min_depth, max_depth = 2, 5
    else: min_depth, max_depth = 1, 5
    
    for depth in range(min_depth, max_depth):
        for i, j in get_empty_squares(board):
            board[i][j] = 'O'
            score = minimax(board, depth, -math.inf, math.inf, False, memory)
 #becaus we need the memory for the recursive function i'm just giving an empty memory so it doesn't make an error
            board[i][j] = ' '
            if score > best_score:
                best_score = score
                move = (i, j)
    return move

class tic_tac_toe_game: #game ui class
    def __init__(self, root):
        self.root = root
        #a dialog that user gets to enter a amount for the board's size
        self.size = simpledialog.askinteger("Board Size", "Enter board size:", minvalue=3)
        if not self.size:
            self.root.destroy()
            return
        self.board = create_board(self.size)
        self.human_turn = True
        self.buttons = []
        self.create_ui()
    
    def create_ui(self):
        self.row_labels = [chr(65 + i) for i in range(self.size)]  #['A', 'B', 'C', ...]
        self.column_labels = [str(i + 1) for i in range(self.size)]  #['1', '2', '3', ...]
        for i in range(self.size):
            row_buttons = []
            for j in range(self.size):
                btn = tk.Button(self.root, text=' ', font=('Arial', 16), width=3, height=1,
                                command=lambda r=i, c=j: self.human_move(r, c))
                btn.grid(row=i + 1, column=j + 1)  #offset by 1 to account for labels
                row_buttons.append(btn)
            self.buttons.append(row_buttons)
        #adding labels on the rows
        for i in range(self.size):
            label = tk.Label(self.root, text=self.row_labels[i], font=('Arial', 16), width=3, height=1)
            label.grid(row=i + 1, column=0)  #putting row labels in the first column
        #adding labels on the columns
        for j in range(self.size):
            label = tk.Label(self.root, text=self.column_labels[j], font=('Arial', 16), width=3, height=1)
            label.grid(row=0, column=j + 1)  #putting column labels in the first row
    
    def human_move(self, row, col):#this is a function for writing and caching human move
        if self.board[row][col] == ' ' and self.human_turn:
            self.board[row][col] = 'X'
            self.buttons[row][col].config(text='X', state=tk.DISABLED)
            print(f"Player moved to {self.row_labels[row]}{col + 1}")
            self.human_turn = False
            self.check_status()
            self.root.after(500, self.ai_move)
    
    def ai_move(self): #this just a function to use best_move function for ai and show it for the user
        if not self.human_turn and not board_is_full(self.board):
            import datetime
            clock = datetime.datetime.now()
            row, col = best_move(self.board)
            print(datetime.datetime.now() - clock)
            # print(len(get_empty_squares(self.board)))
            # print(get_empty_squares(self.board))
            if row != -1:
                self.board[row][col] = 'O'
                self.buttons[row][col].config(text='O', state=tk.DISABLED)
                print(f"AI moved to {self.row_labels[row]}{col + 1}")
            self.human_turn = True
            self.check_status()
    
    def check_status(self): #it checks that if the board is full it's gonna show the scores and who has won
        if board_is_full(self.board):
            human_score, ai_score = evaluate_board(self.board)[1], evaluate_board(self.board)[2]
            result = f"Final Scores:\nYou: {human_score}\nAI: {ai_score}\n"
            print(f"\nFinal Scores:\nYou: {human_score}\nAI: {ai_score}")
            if human_score > ai_score:
                result += "You win!"
                print("You win!")
            elif ai_score > human_score:
                result += "AI wins!"
                print("AI wins!")
            else:
                result += "It's a draw!"
                print("It's a draw!")
            messagebox.showinfo("Game Over", result)
            self.root.quit()

if __name__ == "__main__":
    root = tk.Tk()
    root.title("Tic_Tac_Toe")
    tic_tac_toe_game(root)
    root.mainloop()