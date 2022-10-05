extends Control

#The text the user sees, the equation when entering it, and then the answer after hitting equals
var display_text := ""
#The internal representation of the equation that the user doesnt see
var internal_equation = []
#Operator stack for converting infix to postfix
var operators = []
#Output stack for storing numbers and ultimately the postfix equation
var output = []
#Stack for calculating the answer
var answer = []
#Variable for keeping the current number being entered by the user
var current_num = ""
#Boolean for checking if the user is in the process of entering a number
var is_num := false
#Boolean for flaging an invalid input
var was_invalid := false
#Boolean for flaging error during calculation
var bad_calculation := false
const max_int = 9223372036854775807
const min_int = (-9223372036854775807 - 1)
#19 digits for max values

#State of the calculator used to disable or enable buttons
enum STATE{
	OPEN,
	NUMBER,
	OPERATOR,
	FUNCTION,
	LEFTP,
	RIGHTP,
	DECIMAL,
	UNARY,
	EQUAL
}

var state = STATE.OPEN


#called when starting application
func _ready():
	pass # Replace with function body.


#Activates every frame
func _process(delta):
	#sets the display text so the user can see what they are entering
	get_node("ColorRect").get_node("Display").text = display_text
	#Should be commented out, is for debugging purposes and seeing internal equation
	debug_display()
	#disables or enables buttons based on last button pressed
	control_user()
	
	#Checks if there was an error on the last calculation
	#clears out the error message and sets the boolean to mean "there was not an error anymore"
func previously_invalid():
	if was_invalid:
		was_invalid = false
		display_text = ""

#Not part of the user interation
#Prints the internal stacks to the display for debugging purposes
func debug_display():
	get_node("ColorRect").get_node("Internal").text = internal_equation as String
	get_node("ColorRect").get_node("Output").text = output as String
	
	
#control_user() is called every frame
#Whenever a button is pressed it changes the ENUM stored in the state variable
#The state is compared, depending on which state is active, buttons are disabled to prevent the user from making an error
#buttons are checked in groups
#"func" refers to trig functions like sin and logarithmic functions like ln
#"left_p" is ( and {
#"right_p" is ) and }
#"equal" is =
#"unary" is negation and unary operators
#"binary" is binary operators like + and *
#"decimal" is the decimal
#"clear" is the clear button
func control_user():
	#Activates all buttons to reset previous disable
	for node in get_node("Buttons").get_children():
		node.disabled = false
		
	#Disables buttons based on state
	if state == STATE.EQUAL:
		for node in get_node("Buttons").get_children():
			if not node.is_in_group("clear"):
				node.disabled = true
	if state == STATE.OPEN:
		for node in get_node("Buttons").get_children():
			if node.is_in_group("equal") or node.is_in_group("binary") or node.is_in_group("right_p"):
				node.disabled = true
	if state == STATE.NUMBER:
		for node in get_node("Buttons").get_children():
			if node.is_in_group("func") or node.is_in_group("left_p") or node.is_in_group("unary"):
				node.disabled = true
	if state == STATE.FUNCTION:
		for node in get_node("Buttons").get_children():
			if node.is_in_group("binary") or node.is_in_group("right_p") or node.is_in_group("equal"):
				node.disabled = true
	if state == STATE.OPERATOR:
		for node in get_node("Buttons").get_children():
			if node.is_in_group("binary") or node.is_in_group("right_p") or node.is_in_group("equal"):
				node.disabled = true
	if state == STATE.LEFTP:
		for node in get_node("Buttons").get_children():
			if node.is_in_group("right_p") or node.is_in_group("equal") or node.is_in_group("binary"):
				node.disabled = true
	if state == STATE.RIGHTP:
		for node in get_node("Buttons").get_children():
			if node.is_in_group("func") or node.is_in_group("left_p") or node.is_in_group("decimal") or node.is_in_group("num") or node.is_in_group("unary"):
				node.disabled = true
	if state == STATE.DECIMAL:
		for node in get_node("Buttons").get_children():
			if not node.is_in_group("num"):
				node.disabled = true
	if state == STATE.UNARY:
		for node in get_node("Buttons").get_children():
			if node.is_in_group("binary") or node.is_in_group("right_p") or node.is_in_group("equal"):
				node.disabled = true

		
#When entering numbers they are not pushed to the output stack until another symbol other than a number is entered
#decimal point is considered a number since it is only used within a number
#function is called on every button that is not a number

func was_number():
	#checks to see if a number was being entered
	if is_num:
		#if the number entered ends with a decimal EX (123.)
		#adds a zero at the end of the number to make it valid while keeping the same value
		if current_num.ends_with("."):
			current_num += "0"
			display_text += "0"
		#count is the number of decimal points in ther number
		var count = 0
		for i in current_num:
			if i == ".":
				count += 1
		#If there are more than one decimal point in a number prints out an error
		if count > 1:
			invalid_input("ERROR: A number can only have one decimal point")
			return true
		if count > 0:
			if current_num.length() > 17:
				invalid_input("ERROR: double too large")
		if current_num.length() > 19:
			invalid_input("ERROR: integer too large")
			return true
		if current_num > "9223372036854775807":
			invalid_input("ERROR: integer too large")
			return true
		
		#If valid push the number to the stack and clear out the current number so more can be entered
		internal_equation.append(current_num)
		current_num = ""
		is_num = false
		return false

func invalid_input(message):
	_on_Clear_button_down()
	was_invalid = true
	display_text = message

#Converts the enquation entered by the user (infix notation) to postfix notation to prepare it for evaluation
func shunting_yard():
	while internal_equation.size() > 0:
		#If first token is a number add it to output
		if internal_equation.front().is_valid_float():
			output.append(internal_equation.pop_front())
		
		#Checks if token is a + or - 
		elif internal_equation.front() == "+" or internal_equation.front() == "-":
			#Checks if other operators are in the operator stack is of equal or greater precedence
			while operators.size() > 0:
				if operators.back() == "-" or operators.back() == "+":
					output.append(operators.pop_back())
				elif operators.back() == "*" or operators.back() == "/":
					output.append(operators.pop_back())	
				elif operators.back() == "^":
					output.append(operators.pop_back())
				elif operators.back() == "neg":
					output.append(operators.pop_back())
				elif operators.back() == "sin" or operators.back() == "cos" or operators.back() == "cot" or operators.back() == "tan" or operators.back() == "log" or operators.back() == "ln":
					output.append(operators.pop_back())
				else:
					operators.append(internal_equation.pop_front())
					break
			#if no operator add current token to stack
			if operators.empty():
				operators.append(internal_equation.pop_front())
					
					
		elif internal_equation.front() == "*" or internal_equation.front() == "/":
			#Checks if other operators are in the operator stack is of equal or greater precedence
			while operators.size() > 0:
				if operators.back() == "*" or operators.back() == "/":
					output.append(operators.pop_back())	
				elif operators.back() == "^":
					output.append(operators.pop_back())
				elif operators.back() == "neg":
					output.append(operators.pop_back())
				elif operators.back() == "sin" or operators.back() == "cos" or operators.back() == "cot" or operators.back() == "tan" or operators.back() == "log" or operators.back() == "ln":
					output.append(operators.pop_back())
				else:
					operators.append(internal_equation.pop_front())
					break
			if operators.empty():
				operators.append(internal_equation.pop_front())
					
		elif internal_equation.front() == "^":
			#Checks if other operators are in the operator stack is of greater precedence
			while operators.size() > 0:
				if operators.back() == "neg":
					output.append(operators.pop_back())
				elif operators.back() == "sin" or operators.back() == "cos" or operators.back() == "cot" or operators.back() == "tan" or operators.back() == "log" or operators.back() == "ln":
					output.append(operators.pop_back())
				else:
					operators.append(internal_equation.pop_front())
					break
			if operators.empty():
				operators.append(internal_equation.pop_front())
		
		#push left parentheses and brackets no question
		elif internal_equation.front() == "(" or internal_equation.front() == "{":
			operators.append(internal_equation.pop_front())
			
		#if right } pop operators until the matching left { is found
		elif internal_equation.front() == "}":
			#no mathcing { error
			if operators.empty():
				invalid_input("ERROR: Mismatching { }")
				return
			while operators.size() > 0:
				if operators.back() != "{":
					output.append(operators.pop_back())
				elif operators.back() == "{":
					internal_equation.pop_front()
					operators.pop_back()
					break
				else:
					invalid_input("ERROR: Mismatching { }")
					return
			
		#same as above code only checking for ( instead
		elif internal_equation.front() == ")":
			if operators.empty():
				invalid_input("ERROR: Mismatching ( )")
				return
			while operators.size() > 0:
				if operators.back() != "(":
					output.append(operators.pop_back())
				elif operators.back() == "(":
					internal_equation.pop_front()
					operators.pop_back()
					break
				else:
					invalid_input("ERROR: Mismatching ( )")
					return
		#catches functions as they are pushed whenever they are encountered
		else:
			operators.append(internal_equation.pop_front())
			
	#If there are still operators on the operator stack push them all to the output stack
	if operators.size() > 0:
		while operators.size() > 0:
			#at this point there should not be any left brackets or parentheses if a correct equation was inputted
			if operators.back() == "{":
				invalid_input("ERROR Mismatching { }")
				break
			if operators.back() == "(":
				invalid_input("ERROR Mismatching ( )")
				break
			output.append(operators.pop_back())
		
		
		

func evaluate():
	while output.size() > 0:
		if bad_calculation:
			return
		if output.front().is_valid_integer():
			answer.append(output.pop_front() as int)
		elif output.front().is_valid_float():
			answer.append(output.pop_front() as float)
		elif output.front() == "+":
			output.pop_front()
			var y = answer.pop_back()
			var x = answer.pop_back()
			answer.push_back(add(x,y))
		elif output.front() == "-":
			output.pop_front()
			var y = answer.pop_back()
			var x = answer.pop_back()
			answer.push_back(subtract(x,y))
		elif output.front() == "*":
			output.pop_front()
			var y = answer.pop_back()
			var x = answer.pop_back()
			answer.push_back(multiply(x,y))
		elif output.front() == "/":
			output.pop_front()
			var y = answer.pop_back()
			var x = answer.pop_back()
			answer.push_back(divide(x,y))
		elif output.front() == "^":
			output.pop_front()
			var y = answer.pop_back()
			var x = answer.pop_back()
			answer.push_back(exponent(x,y))
		elif output.front() == "neg":
			output.pop_front()
			var x = answer.pop_back()
			answer.push_back(negate(x))
		elif output.front() == "cos":
			output.pop_front()
			var x = answer.pop_back()
			answer.push_back(cos(x))
		elif output.front() == "sin":
			output.pop_front()
			var x = answer.pop_back()
			answer.push_back(sin(x))
		elif output.front() == "tan":
			output.pop_front()
			var x = answer.pop_back()
			answer.push_back(tan(x))
		elif output.front() == "cot":
			output.pop_front()
			var x = answer.pop_back()
			answer.push_back(cot(x))
		elif output.front() == "log":
			output.pop_front()
			var x = answer.pop_back()
			answer.push_back(log10(x))
		elif output.front() == "ln":
			output.pop_front()
			var x = answer.pop_back()
			answer.push_back(ln(x))
		

func add(x, y):
	if (x > 0 and y > 0) and x + y < 0 :
		bad_calculation = true
		display_text = "ERROR: integer overflow"
		return 1
	#CONTINUE HERE
	if (x < 0 and y < 0) and x + y > 0 :
		bad_calculation = true
		display_text = "ERROR: integer underflow"
		return 1
	return x + y
	
func subtract(x, y):
	if (x < 0 and y > 0) and x - y > 0:
		bad_calculation = true
		display_text = "ERROR: integer underflow"
		return 1
	if (x > 0 and y < 0) and x - y < 0:
		bad_calculation = true
		display_text = "ERROR: integer overflow"
		return 1
	return x - y
	
func multiply(x, y):
	if (x < 0 and y > 0) and x * y > 0:
		bad_calculation = true
		display_text = "ERROR: integer underflow"
		return 1
	if (x > 0 and y < 0) and x * y > 0:
		bad_calculation = true
		display_text = "ERROR: integer underflow"
		return 1
	if (x > 0 and y > 0) and x * y < 0:
		bad_calculation = true
		display_text = "ERROR: integer overflow"
		return 1
	return x * y

func divide(x, y):
	if y == 0:
		bad_calculation = true
		display_text = "ERROR: divide by zero"
		return 1
	
	return x / y

func exponent(x, y):
	if pow(x,y) == INF:
		bad_calculation = true
		display_text = "ERROR: integer overflow"
		return 1
	if pow(x,y) == -INF:
		bad_calculation = true
		display_text = "ERROR: integer underflow"
		return 1
	return  pow(x, y)

func log10(x):
	if x <= 0:
		bad_calculation = true
		display_text = "ERROR: log can only accept numbers > 0"
		return 1
	return log(x) / log(10)

func ln(x):
	if x <= 0:
		bad_calculation = true
		display_text = "ERROR: log can only accept numbers > 0"
		return 1
	return log(x)
	
func cot(x):
	if sin(x) == 0:
		bad_calculation = true
		display_text = "ERROR: divide by zero"
		return 1
	return cos(x) / sin(x)
	
func negate(x):
	return x * -1



#The following functions are called whenever a button is pressed
#You can see in the function name what button is being pressed
#All buttons set the state depending on the type of symbol to disable some of the buttons for the next input to avoid improper equations
#display_text is the equation the user sees
#internal_equation is the actual equation being processed, hidden away from the user
#For example the following function is for the equals button
func _on_Equal_button_down():
	previously_invalid()
	state = STATE.EQUAL
	was_number()
	shunting_yard()
	if was_invalid:
		return
	evaluate()
	if bad_calculation:
		return
	display_text = answer.pop_back() as String
	
func _on_Clear_button_down():
	internal_equation = []
	operators = []
	output = []
	answer = []
	current_num = ""
	display_text = ""
	is_num = false
	was_invalid = false
	bad_calculation = false
	state = STATE.OPEN
	

func _on_LeftBracket_button_down():
	previously_invalid()
	state = STATE.LEFTP
	display_text += "{"
	internal_equation.append("{")
	


func _on_Log_button_down():
	previously_invalid()
	state = STATE.FUNCTION
	display_text += "log("
	internal_equation.append("log")
	internal_equation.append("(")


func _on_Sin_button_down():
	previously_invalid()
	state = STATE.FUNCTION
	display_text += "sin("
	internal_equation.append("sin")
	internal_equation.append("(")


func _on_Tan_button_down():
	previously_invalid()
	state = STATE.FUNCTION
	display_text += "tan("
	internal_equation.append("tan")
	internal_equation.append("(")
	


func _on_RightBracket_button_down():
	previously_invalid()
	state = STATE.RIGHTP
	display_text += "}"
	if was_number():
		return
	internal_equation.append("}")


func _on_Ln_button_down():
	previously_invalid()
	state = STATE.FUNCTION
	display_text += "ln("
	internal_equation.append("ln")
	internal_equation.append("(")


func _on_Cos_button_down():
	previously_invalid()
	state = STATE.FUNCTION
	display_text += "cos("
	internal_equation.append("cos")
	internal_equation.append("(")


func _on_Cot_button_down():
	previously_invalid()
	state = STATE.FUNCTION
	display_text += "cot("
	internal_equation.append("cot")
	internal_equation.append("(")


func _on_7_button_down():
	previously_invalid()
	state = STATE.NUMBER
	is_num = true
	display_text += "7"
	current_num += "7"


func _on_4_button_down():
	previously_invalid()
	state = STATE.NUMBER
	is_num = true
	display_text += "4"
	current_num += "4"


func _on_1_button_down():
	previously_invalid()
	state = STATE.NUMBER
	is_num = true
	display_text += "1"
	current_num += "1"


func _on_Negative_button_down():
	previously_invalid()
	state = STATE.UNARY
	display_text += "-"
	internal_equation.append("neg")
	


func _on_8_button_down():
	previously_invalid()
	state = STATE.NUMBER
	is_num = true
	display_text += "8"
	current_num += "8"


func _on_5_button_down():
	previously_invalid()
	state = STATE.NUMBER
	is_num = true
	display_text += "5"
	current_num += "5"


func _on_2_button_down():
	previously_invalid()
	state = STATE.NUMBER
	is_num = true
	display_text += "2"
	current_num += "2"


func _on_0_button_down():
	previously_invalid()
	state = STATE.NUMBER
	is_num = true
	display_text += "0"
	current_num += "0"


func _on_9_button_down():
	previously_invalid()
	state = STATE.NUMBER
	is_num = true
	display_text += "9"
	current_num += "9"


func _on_6_button_down():
	previously_invalid()
	state = STATE.NUMBER
	is_num = true
	display_text += "6"
	current_num += "6"


func _on_3_button_down():
	previously_invalid()
	state = STATE.NUMBER
	is_num = true
	display_text += "3"
	current_num += "3"


func _on_Decimal_button_down():
	previously_invalid()
	state = STATE.DECIMAL
	if is_num:
		display_text += "."
		current_num += "."
	else:
		display_text += "0."
		current_num += "0."
		is_num = true


func _on_LeftParen_button_down():
	previously_invalid()
	state = STATE.LEFTP
	display_text += "("
	internal_equation.append("(")


func _on_Divide_button_down():
	previously_invalid()
	state = STATE.OPERATOR
	display_text += "/"
	if was_number():
		return
	internal_equation.append("/")


func _on_Subtract_button_down():
	previously_invalid()
	state = STATE.OPERATOR
	display_text += "-"
	if was_number():
		return
	internal_equation.append("-")


func _on_Exponent_button_down():
	previously_invalid()
	state = STATE.OPERATOR
	display_text += "^("
	if was_number():
		return
	internal_equation.append("^")
	internal_equation.append("(")


func _on_RightParen_button_down():
	previously_invalid()
	state = STATE.RIGHTP
	display_text += ")"
	if was_number():
		return
	internal_equation.append(")")


func _on_Multiply_button_down():
	previously_invalid()
	state = STATE.OPERATOR
	display_text += "*"
	if was_number():
		return
	internal_equation.append("*")


func _on_Add_button_down():
	previously_invalid()
	state = STATE.OPERATOR
	display_text += "+"
	if was_number():
		return
	internal_equation.append("+")
