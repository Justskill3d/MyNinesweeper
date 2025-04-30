extends Node

@export var lives=1
@export var gold=1
@export var maxlife=3

# Called when the node enters the scene tree for the first time.
func _ready():
	
	setLives(3)
	setGold(10)
	
	pass # Replace with function body.

func setLives(n):
	lives=n
	
func addLives(n):
	if n+lives>=maxlife:
		setLives(maxlife)
	else:
		lives=lives+n
		
func addMaxlife(n):
	maxlife=maxlife+n
	
func updateStats(damage):
	setLives(lives-damage)
	if lives<=0:
		setLives(0)
		#GameOver
	print(lives)	
	
func setGold(newgold):
	gold=newgold

func addGold(n):
	setGold(gold+n)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.

