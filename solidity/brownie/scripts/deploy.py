from scripts.helpful_scripts import get_account
from brownie import interface, config, network, accounts, Consumer
import sys

L2_CONTRACT = 731483252570105677457428171671115871155192009051060175976932354198821779957
STARKNET_CORE = "0xde29d060D45901Fb19ED6C6e959EB22d8626708e"


def main():
    deploy()

def deploy():
    account = get_account()
    consumer = Consumer.deploy(L2_CONTRACT, STARKNET_CORE, {"from": account}, publish_source=True )
    print("Consumer deployed to: ", consumer.address)

    