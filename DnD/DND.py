import os
import random
import argparse
from notion_client import Client
import readchar

notion_api_key = os.environ.get("NOTION_API_KEY")
database_id = os.environ.get("NOTION_DATABASE_ID")

if not notion_api_key or not database_id:
    raise SystemExit("Please set NOTION_API_KEY and NOTION_DATABASE_ID environment variables.")

def rolldie(sides):
    return random.randint(1, sides)

client = Client(auth=notion_api_key)

def insert_into_notion(result, sides, roll_type="Standard", modifier=0, final_result=None):
    """
    Insert roll into Notion database
    roll_type: Initiative, Advantage, Disadvantage, Standard, etc.
    """
    if final_result is None:
        final_result = result

    client.pages.create(
        parent={"database_id": database_id},
        properties={
            "Roll": {
                "title": [
                    {
                        "text": {
                            "content": f"{final_result} ({roll_type})"
                        }
                    }
                ]
            },
            "Sides": {
                "number": sides
            }
        }
    )
    print(f"Roll logged to Notion: {final_result} ({roll_type})")

def roll_initiative():
    """Roll initiative with dex modifier - returns True if went back, False otherwise"""
    print("Press ESC to go back\n")
    dex_mod = input("Enter your Dexterity modifier: ").strip()

    if not dex_mod.lstrip('-').isdigit():
        print("Invalid modifier. Please enter a number.")
        input("\nPress Enter to continue...")
        return False

    dex_mod = int(dex_mod)
    roll = rolldie(20)
    total = roll + dex_mod

    modifier_str = f"+{dex_mod}" if dex_mod >= 0 else str(dex_mod)
    print(f"\nInitiative Roll: {roll} {modifier_str} = {total}")

    insert_into_notion(roll, 20, f"Initiative {modifier_str}", dex_mod, total)
    return False

def roll_d20_general():
    """General d20 roll with advantage/disadvantage and modifier options - returns True if went back"""
    roll1 = rolldie(20)
    if roll1 == 20:
        print("\n🎉 Critical Hit! You rolled a natural 20! 🎉")
    print(f"\nYou rolled: {roll1}")

    final_roll = roll1
    roll_type = "Standard"

    # First, check for advantage/disadvantage
    while True:
        print("\n1. Advantage (roll again, take higher)")
        print("2. Disadvantage (roll again, take lower)")
        print("3. Keep this roll")
        print("4. Go Back (don't log this roll)")

        choice = input("\nSelect option (1-4): ").strip()

        if choice == "1":
            # Advantage - roll again and take higher
            roll2 = rolldie(20)
            final_roll = max(roll1, roll2)
            print(f"Second roll: {roll2}")
            print(f"With Advantage, you take: {final_roll}")
            roll_type = f"Advantage ({roll1}, {roll2})"
            break
        elif choice == "2":
            # Disadvantage - roll again and take lower
            roll2 = rolldie(20)
            final_roll = min(roll1, roll2)
            print(f"Second roll: {roll2}")
            print(f"With Disadvantage, you take: {final_roll}")
            roll_type = f"Disadvantage ({roll1}, {roll2})"
            break
        elif choice == "3":
            # Keep original roll
            final_roll = roll1
            roll_type = "Standard"
            break
        elif choice == "4":
            # Go back without logging
            print("Returning to menu...")
            return True
        else:
            print("Invalid choice. Please enter 1-4.")

    # Now ask about modifier
    while True:
        print(f"\nCurrent roll: {final_roll}")
        print("\n1. Add a modifier")
        print("2. Keep roll as is")
        print("3. Go Back (don't log this roll)")

        choice = input("\nSelect option (1-3): ").strip()

        if choice == "1":
            modifier_input = input("Enter modifier (e.g., 5 or -2): ").strip()

            if not modifier_input.lstrip('-').isdigit():
                print("Invalid modifier. Please enter a number.")
                continue

            modifier = int(modifier_input)
            total = final_roll + modifier
            modifier_str = f"+{modifier}" if modifier >= 0 else str(modifier)

            print(f"\nFinal Result: {final_roll} {modifier_str} = {total}")
            insert_into_notion(final_roll, 20, f"{roll_type} {modifier_str}", modifier, total)
            return False
        elif choice == "2":
            # Keep roll without modifier
            insert_into_notion(final_roll, 20, roll_type)
            return False
        elif choice == "3":
            # Go back without logging
            print("Returning to menu...")
            return True
        else:
            print("Invalid choice. Please enter 1-3.")

def clear_screen():
    """Clear the terminal screen"""
    os.system('cls' if os.name == 'nt' else 'clear')

def show_main_menu():
    """Display main menu with arrow key navigation"""
    menu_options = [
        "Roll Initiative (d20 + Dex modifier)",
        "General d20 Roll (with Advantage/Disadvantage option)",
        "Quick Dice Roll (d4, d6, d8, d10, d12, d20, d100)",
        "Quit"
    ]

    selected = 0

    while True:
        clear_screen()
        print("\n" + "="*50)
        print("🎲 DICE ROLLING MENU 🎲")
        print("="*50)
        print("Use ↑/↓ arrow keys to navigate, Enter to select")
        print("Press ESC or Q to quit\n")

        for i, option in enumerate(menu_options):
            if i == selected:
                print(f"  → {option} ←")
            else:
                print(f"    {option}")

        print("="*50)

        # Read key input
        key = readchar.readkey()

        if key == readchar.key.UP:
            selected = (selected - 1) % len(menu_options)
        elif key == readchar.key.DOWN:
            selected = (selected + 1) % len(menu_options)
        elif key == readchar.key.ENTER or key == '\r' or key == '\n':
            clear_screen()
            return selected + 1  # Return 1-4 to match original logic
        elif key == readchar.key.ESC or key == 'q' or key == 'Q':
            return 4  # Quit

def show_dice_menu():
    """Arrow key menu for quick dice selection"""
    dice_options = ["d4", "d6", "d8", "d10", "d12", "d20", "d100", "Go Back"]
    selected = 0

    while True:
        clear_screen()
        print("\n" + "="*50)
        print("🎲 SELECT A DIE 🎲")
        print("="*50)
        print("Use ↑/↓ arrow keys to navigate, Enter to select")
        print("Press ESC to go back\n")

        for i, option in enumerate(dice_options):
            if i == selected:
                print(f"  → {option} ←")
            else:
                print(f"    {option}")

        print("="*50)

        key = readchar.readkey()

        if key == readchar.key.UP:
            selected = (selected - 1) % len(dice_options)
        elif key == readchar.key.DOWN:
            selected = (selected + 1) % len(dice_options)
        elif key == readchar.key.ENTER or key == '\r' or key == '\n':
            if selected == len(dice_options) - 1:  # "Go Back" selected
                return None
            return dice_options[selected]
        elif key == readchar.key.ESC:
            return None

def quick_dice_roll():
    """Quick dice rolling with advantage/disadvantage and modifier - returns True if went back"""
    die_choice = show_dice_menu()

    if die_choice is None:
        return True  # User went back

    sides = int(die_choice.lstrip("d"))
    roll1 = rolldie(sides)

    clear_screen()
    print(f"\n🎲 You rolled a {die_choice}: {roll1}")
    if sides == 20 and roll1 == 20:
        print("\n🎉 Critical Hit! You rolled a natural 20! 🎉")

    final_roll = roll1
    roll_type = "Quick Roll"

    # Check for advantage/disadvantage (only for d20)
    if sides == 20:
        while True:
            print("\n1. Advantage (roll again, take higher)")
            print("2. Disadvantage (roll again, take lower)")
            print("3. Keep this roll")
            print("4. Go Back (don't log this roll)")

            choice = input("\nSelect option (1-4): ").strip()

            if choice == "1":
                # Advantage
                roll2 = rolldie(20)
                final_roll = max(roll1, roll2)
                print(f"Second roll: {roll2}")
                print(f"With Advantage, you take: {final_roll}")
                roll_type = f"Quick Roll Advantage ({roll1}, {roll2})"
                break
            elif choice == "2":
                # Disadvantage
                roll2 = rolldie(20)
                final_roll = min(roll1, roll2)
                print(f"Second roll: {roll2}")
                print(f"With Disadvantage, you take: {final_roll}")
                roll_type = f"Quick Roll Disadvantage ({roll1}, {roll2})"
                break
            elif choice == "3":
                # Keep roll
                final_roll = roll1
                roll_type = "Quick Roll"
                break
            elif choice == "4":
                # Go back
                print("Returning to menu...")
                return True
            else:
                print("Invalid choice. Please enter 1-4.")

    # Ask if they want to add a modifier
    while True:
        print(f"\nCurrent roll: {final_roll}")
        print("\n1. Add a modifier")
        print("2. Keep roll as is")
        print("3. Go Back (don't log this roll)")

        choice = input("\nSelect option (1-3): ").strip()

        if choice == "1":
            modifier_input = input("Enter modifier (e.g., 5 or -2): ").strip()

            if not modifier_input.lstrip('-').isdigit():
                print("Invalid modifier. Please enter a number.")
                continue

            modifier = int(modifier_input)
            total = final_roll + modifier
            modifier_str = f"+{modifier}" if modifier >= 0 else str(modifier)

            print(f"\nFinal Result: {final_roll} {modifier_str} = {total}")
            insert_into_notion(final_roll, sides, f"{roll_type} {modifier_str}", modifier, total)
            return False
        elif choice == "2":
            # Keep roll without modifier
            insert_into_notion(final_roll, sides, roll_type)
            return False
        elif choice == "3":
            # Go back without logging
            print("Returning to menu...")
            return True
        else:
            print("Invalid choice. Please enter 1-3.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Roll dice and log results to Notion.")
    parser.add_argument(
        "die",
        nargs="?",
        help="Type of die to roll (d4, d6, d8, d10, d12, d20, d100) - optional")

    args = parser.parse_args()
    allowed = {4, 6, 8, 10, 12, 20, 100}

    # Command-line mode
    if args.die:
        choice = args.die.lower().lstrip("d")

        if not choice.isdigit() or int(choice) not in allowed:
            print(f"Invalid choice '{choice}'. Please choose from d4, d6, d8, d10, d12, d20, or d100.")
            raise SystemExit(1)

        sides = int(choice)
        result = rolldie(sides)
        print(f"You rolled: {result}")
        insert_into_notion(result, sides, "Quick Roll")

    # Interactive menu mode
    else:
        print("\n🎲 Dice Rolling Tool - Interactive Mode 🎲")

        while True:
            choice = show_main_menu()

            if choice == 1:
                went_back = roll_initiative()
                if not went_back:
                    input("\nPress Enter to return to menu...")
            elif choice == 2:
                went_back = roll_d20_general()
                if not went_back:
                    input("\nPress Enter to return to menu...")
            elif choice == 3:
                went_back = quick_dice_roll()
                if not went_back:
                    input("\nPress Enter to return to menu...")
            elif choice == 4:
                clear_screen()
                print("\nThanks for rolling! Goodbye! 🎲\n")
                break
