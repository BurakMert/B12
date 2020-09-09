# This is a sample Python script.
import argparse
from core import services

import pydantic

# Press ⌃R to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.



def parse_args():
    #Parses command line args in --from <city> --to <city> format
    try:
        parser = argparse.ArgumentParser()
        parser.add_argument('-f', '--from', type=str, help='From city',
                            dest='from_')
        parser.add_argument('-t', '--to', type=str, help='To city',
                            dest='to_')
        args = parser.parse_args()
        return (args.from_, args.to_)
    except KeyError as e:
        print('Key not found in commands: {}'.format(e))
    except Exception as e:
        print('Error in operation, detail: {}'.format(e))






def main():
    frm, to = parse_args()
    flight_optimizer = services.FlightOptimizer(frm, to)
    optimized_route = flight_optimizer.optimize_dpk()
    prepare_output(to, frm, optimized_route)

def prepare_output(to, frm, optimized_route):
    print("Best dollars_per_km route to {} from {} is: {}$".format(to, frm,  optimized_route.dollars_per_km))
    print("Here is the whole route for best dpk: {}".format(optimized_route.routes))

# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    main()

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
