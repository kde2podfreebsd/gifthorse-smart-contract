from eth_hash.auto import keccak
from eth_utils import encode_hex

def hash_leaf(index, account, amount):
    index_bytes = index.to_bytes(32, byteorder='big')
    amount_bytes = amount.to_bytes(32, byteorder='big')

    account_int = int(account.removeprefix("0x"), 16)
    account_bytes = account_int.to_bytes(20, byteorder='big')  

    data = index_bytes + account_bytes + amount_bytes
    return keccak(data)

def merkle_tree(elements):
    if len(elements) == 1:
        return elements[0], [[]]
    if len(elements) % 2 == 1:
        elements.append(elements[-1])
    next_level = []
    proofs = [[] for _ in range(len(elements))]
    for i in range(0, len(elements), 2):
        combined = keccak(elements[i] + elements[i+1])
        next_level.append(combined)
        proofs[i].append(elements[i+1])
        proofs[i+1].append(elements[i])
    root, child_proofs = merkle_tree(next_level)
    for i in range(len(elements)):
        proofs[i] += child_proofs[i // 2]
    return root, proofs

def generate_merkle_proof(elements, index):
    _, proofs = merkle_tree(elements)
    return proofs[index]

data = [
    (0, "0x5e825CF3761117D1F2C70aA445232BfACDd6Ed60", 100000000000000000000), # 100 токенов
    (1, "0xdD85781f20e2a569E4bAc22C5Db207C609e2BB92", 999000000000000000000)
]

hashed_elements = [hash_leaf(index, account, amount) for index, account, amount in data]

root, _ = merkle_tree(hashed_elements)
print(f"Merkle Root: {encode_hex(root)}")

for i in range(len(data)):
    proof = generate_merkle_proof(hashed_elements, i)
    print(f"Proof for element {i}: {[encode_hex(p) for p in proof]}")