# This is a conceptual example and may require adjustments based on the exact SDK version and your specific use case.
from injective.client.chain_client import ChainClient
from injective.wallet.wallet import PrivateKey
from injective.messages.bank import MsgSend

# --- Configuration ---
# Replace with your actual private key and desired network details
private_key_hex = "YOUR_PRIVATE_KEY_HEX"
recipient_address = "INJ_RECIPIENT_ADDRESS"
amount_to_send = "1000000000000000000"  # Example: 1 INJ in wei (10^18)
denom = "inj"
network = "testnet" # Or "mainnet"

# --- Initialize Wallet and Client ---
wallet = PrivateKey.from_hex(private_key_hex)
chain_client = ChainClient(network=network)

# --- Create and Sign the Message ---
msg = MsgSend(
    sender=wallet.address,
    receiver=recipient_address,
    amount=amount_to_send,
    denom=denom
)

# --- Broadcast the Transaction ---
try:
    tx_response = chain_client.send_tx(wallet, [msg])
    print(f"Transaction sent: {tx_response.txhash}")
    # You can also check tx_response.code for success/failure
except Exception as e:
    print(f"Error sending transaction: {e}")