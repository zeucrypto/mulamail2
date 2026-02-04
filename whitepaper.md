
# MulaMail 2.0: The Unified Protocol for Financial Communication

**White Paper v1.0**
**Date:** February 2026
**Native Token:** ZEU

---

## 1. Abstract

MulaMail 2.0 represents a paradigm shift in digital communication, effectively merging the semantic layer of email with the value layer of the blockchain. In the current Web2 landscape, communication (email/chat) and finance (banking/wallets) exist in disjointed silos, creating friction, security vulnerabilities, and identity fragmentation. MulaMail 2.0 resolves this by introducing a decentralized, non-custodial mail client built on the Solana blockchain, utilizing **ZK Compression** for infinite scalability and **MPC (Multi-Party Computation)** for seamless user onboarding.

The core innovation of MulaMail 2.0 is the "Programmable Inbox." By leveraging **Solana Blinks (Blockchain Links)** and **Actions**, emails are no longer static text documents but dynamic, executable interfaces. A user can pay an invoice, vote in a DAO, or mint an NFT directly within the email body, signed securely by their embedded wallet. This ecosystem is powered by the **ZEU Token**, a utility asset designed to abstract gas fees, incentivize storage, and govern the protocol's anti-spam parameters.

---

## 2. Introduction

### 2.1 The Evolution of Digital Communication

For over thirty years, the Simple Mail Transfer Protocol (SMTP) has served as the backbone of global communication. While robust, SMTP was designed in an era before digital value transfer. It lacks native encryption, identity verification is easily spoofed, and it cannot carry value (money) natively.

As the world transitions to Web3, users are forced to manage two distinct digital identities:

1. **The Email Address:** Their semantic identity (e.g., `alice@gmail.com`).
2. **The Wallet Address:** Their financial identity (e.g., `8xrt...3kL9`).

This separation creates a "Cognitive Gap." Users must copy-paste cryptographic addresses from emails to wallets, exposing them to phishing attacks, clipboard hijacking, and operational errors.

### 2.2 The Web3 Onboarding Problem

Despite the promise of decentralized finance (DeFi), mass adoption faces a critical hurdle: key management. The requirement to safeguard a 12-word seed phrase is a non-starter for the average internet user. Current solutions are either fully custodial (centralized exchanges) or fully self-sovereign (hardware wallets), with no middle ground that offers the ease of Web2 with the ownership of Web3.

### 2.3 The MulaMail 2.0 Vision

MulaMail 2.0 envisions a world where "sending an email" and "sending a transaction" are the same action. We are building a system where:

* **Identity is Unified:** Your email address is your public key.
* **Storage is Hybrid:** Privacy is guaranteed by strong encryption, while costs are minimized by cloud storage.
* **Interaction is Native:** Applications live inside the message.

---

## 3. Technical Architecture

MulaMail 2.0 utilizes a **Hybrid Architecture** that balances the trustlessness of blockchain with the performance of cloud computing. The system comprises three primary layers: The Identity Layer (Solana), The Storage Layer (AWS S3 + IPFS), and The Interaction Layer (Client).

### 3.1 The Identity Layer: ZK Compression & Account Abstraction

One of the primary challenges of building a blockchain-based email system is the cost of "State." On Solana, creating a standard Token Account or PDA (Program Derived Address) requires a "Rent" deposit (approx. 0.002 SOL). For a platform targeting 100 million users, this would require millions of dollars in locked capital.

**Solution: ZK Compression**
MulaMail 2.0 integrates **ZK Compression** (powered by Light Protocol) to solve this scaling bottleneck.

* **Merkle State Trees:** Instead of storing every user's account state (e.g., inbox settings, public keys, ZEU token balance) directly in Solana's expensive RAM, we store user data in off-chain ledger space, compressed into a 32-byte Merkle Root stored on-chain.
* **Validity Proofs:** When a user updates their settings or receives a ZEU transfer, the system generates a Zero-Knowledge Validity Proof (SNARK) to prove that the state transition is valid without revealing the entire dataset to the main chain.
* **Cost Reduction:** This reduces the cost of onboarding a user from ~$0.40 to <$0.0001, making "free accounts" economically viable.

### 3.2 The Cryptography Layer: The Ed25519-X25519 Bridge

Solana wallets utilize the **Ed25519** elliptic curve for digital signatures. However, Ed25519 is not designed for encryption. To enable End-to-End Encryption (E2EE) without requiring users to manage a second set of keys, MulaMail 2.0 implements a deterministic key derivation bridge.

The mathematical transformation is defined as:


**The Workflow:**

1. **Sender (Alice):** Retrieves Recipient (Bob)'s Solana Ed25519 Public Key.
2. **Conversion:** Alice's client converts Bob's public key to the Curve25519 (X25519) format.
3. **ECDH Handshake:** Alice generates an ephemeral key pair and performs an Elliptic Curve Diffie-Hellman (ECDH) exchange with Bob's converted public key to derive a `Shared_Secret`.
4. **Encryption:** The email body is encrypted using `XSalsa20-Poly1305` or `AES-256-GCM` using the `Shared_Secret`.
5. **Decryption:** Bob's client uses his private key (converted to scalar format) to reconstruct the `Shared_Secret` and decrypt the message.

This ensures that **neither MulaMail 2.0 servers nor AWS S3** can ever read the contents of the emails, as they do not possess the private scalar required to derive the shared secret.

### 3.3 The Storage Layer: Encrypted Blobs on S3

Storing email bodies on-chain is inefficient and privacy-preserving disasters. MulaMail 2.0 uses a "Pointer System":

* **On-Chain/Index:** Contains metadata: `Sender`, `Receiver`, `Timestamp`, `Content-Hash (SHA256)`, and `Action-Type`.
* **Off-Chain (S3):** Contains the encrypted ciphertext.

**Access Control via Signed Pointers:**
To retrieve an email, the user's client must sign a challenge message `{"action": "read", "id": "email_123"}`. The backend verifies this signature against the user's Solana address and issues a temporary **AWS S3 Presigned URL**, granting read access for 60 seconds.

---

## 4. Identity & Onboarding: The MPC Revolution

MulaMail 2.0 removes the need for seed phrases through **Threshold Multi-Party Computation (MPC)**.

### 4.1 Key Sharding (2-of-3 Model)

When a user signs up with Google/Apple:

1. **Shard A (Device Share):** Generated and stored in the user's device Secure Enclave (e.g., FaceID subsystem).
2. **Shard B (Social Share):** Encrypted and stored by the MulaMail Auth Nodes, unlocked only via a valid OIDC token (e.g., successful Google Login).
3. **Shard C (Recovery Share):** Encrypted with a user-defined PIN or answer and stored in cold storage (IPFS/Arweave).

### 4.2 Reconstruction

To sign a transaction or decrypt an email, the user needs **2 out of 3 shards**.

* **Daily Use:** Device Share + Social Share = Full Private Key (reconstructed ephemerally in memory).
* **Device Loss:** Social Share + Recovery Share allows the user to regenerate the Device Share on a new phone.

### 4.3 The "Shadow Wallet" for Web2 Users

If a MulaMail user sends an encrypted email to a non-user (e.g., `bob@yahoo.com`), the protocol automatically creates a **Shadow Wallet**.

1. A temporary key pair is generated.
2. The private key is encrypted with a master key derived from the recipient's email hash and stored in a "Holding Smart Contract."
3. The recipient receives a standard legacy email with a link.
4. Upon clicking and authenticating via OAuth, the Shadow Wallet is upgraded to a full MPC wallet, and the private key is handed over to the user.

---

## 5. The Programmable Inbox: Solana Blinks & Actions

The defining feature of MulaMail 2.0 is the **Programmable Inbox**. We leverage the **Solana Actions** standard (GET/POST specification) to turn URLs into interfaces.

### 5.1 Dynamic Rendering

When MulaMail 2.0 detects a specialized URL (e.g., `solana-action:https://jup.ag/swap/SOL-ZEU`) in the email body, it does not render a blue hyperlink. Instead, the client fetches the metadata from that URL and renders a **Blink (Blockchain Link)**.

A Blink is a standardized UI Card component containing:

* **Icon & Title:** (e.g., "Jupiter Exchange")
* **Input Fields:** (e.g., "Amount to Swap")
* **Action Buttons:** (e.g., "Confirm Swap")

### 5.2 Use Cases

1. **Invoice Settlement:** A freelancer sends an invoice. The email *is* the payment terminal. The client sees a "Pay 500 USDC" button. Clicking it prompts the embedded wallet to sign the transfer. The invoice status updates to "Paid" on-chain instantly.
2. **Governance:** A DAO sends a proposal. The email contains "Vote Yes" and "Vote No" buttons. The user votes without leaving the inbox.
3. **Token Gating:** An email's content is encrypted such that it can only be decrypted if the recipient's wallet holds a specific NFT (verified via local proof).

### 5.3 Security Sandbox

To prevent malicious actions (e.g., a button that says "Claim Airdrop" but drains the wallet), MulaMail 2.0 implements a strict **Execution Sandbox**:

* **Domain Allow-listing:** Only trusted Action Providers are rendered by default. Unknown domains show a warning.
* **Transaction Simulation:** Before the user signs, the client runs a `simulateTransaction` RPC call. If the simulation shows asset balances decreasing unexpectedly, the UI turns red and blocks the signature.

---

## 6. The ZEU Token Economy

The **ZEU Token** is the native utility and governance asset of the MulaMail 2.0 ecosystem. It is designed to capture the value of the network's usage while minimizing friction for end-users.

### 6.1 Token Utility

1. **Gas Abstraction (Fee Sponsorship):**
* New users do not have SOL for gas.
* **The Relay System:** Users can pay for transaction fees using ZEU (or even USDC). The MulaMail Relayer pays the SOL gas on-chain and deducts the equivalent ZEU from the user's balance.


2. **Storage Premium:**
* Free users have a storage cap (e.g., 1GB).
* Staking ZEU unlocks "Premium Tiers" (100GB, 1TB) and "Permanent Storage" on Arweave.


3. **Proof-of-Stake Communication (Anti-Spam):**
* To send a cold email to a stranger, the sender must "attach" a micro-stake of ZEU (e.g., 0.1 ZEU).
* If the recipient marks the email as Spam, the 0.1 ZEU is burned (deflationary).
* If the recipient replies, the 0.1 ZEU is returned to the sender.
* This economic hurdle makes high-volume spamming mathematically unprofitable.



### 6.2 Token Distribution (Total Supply: 1,000,000,000 ZEU)

* **Community & Ecosystem (40%):** Airdrops for early adopters, grants for plugin developers, and user growth incentives.
* **Treasury (20%):** Reserved for future protocol development and liquidity provision.
* **Team & Contributors (15%):** Vested over 4 years with a 1-year cliff.
* **Investors (15%):** Seed and Private rounds.
* **Liquidity Bootstrapping (10%):** Initial DEX offerings (IDO) and CEX listings.

### 6.3 Deflationary Mechanics

* **Spam Burns:** As mentioned, spammers burn ZEU.
* **Plugin Fees:** 1% of fees generated by premium plugins (e.g., a paid newsletter subscription plugin) are used to buy back and burn ZEU.

---

## 7. Governance & DAO

MulaMail 2.0 will transition to a **Decentralized Autonomous Organization (DAO)**.

* **Phase 1 (Centralized):** The core team controls the protocol parameters (spam thresholds, fee rates) to ensure stability during the beta.
* **Phase 2 (Hybrid):** ZEU holders can vote on "Signal Proposals" to guide development.
* **Phase 3 (Full DAO):** The protocol's upgrade keys are transferred to a Timelock Governance Contract. ZEU holders vote directly on smart contract upgrades and Treasury allocations.

---

## 8. Security & Threat Modeling

### 8.1 Threat: Compromised AWS S3 Keys

If an attacker gains access to the AWS S3 buckets:

* **Impact:** They can download the encrypted blobs.
* **Mitigation:** They *cannot* decrypt them. The decryption keys reside only on the user's device (MPC shards). The data is mathematically useless to the attacker (High Entropy Noise).

### 8.2 Threat: Malicious Plugin (Phishing)

An attacker creates an email that looks like a legitimate invoice but is a "Drainer."

* **Mitigation 1:** The **MulaMail Registry** assigns a "Verified Checkmark" to known domains (e.g., PayPal, Coinbase).
* **Mitigation 2:** The client performs semantic analysis on the transaction instruction data. If it detects a `SetAuthority` or `ApproveAll` instruction on a suspicious contract, it auto-rejects the request.

---

## 9. Roadmap

**Q1 2026: The Alpha (MVP)**

* Launch of Web Client (MulaMail.io).
* Integration of Privy/Web3Auth for MPC Login.
* Basic Email Send/Receive with Ed25519->X25519 Encryption.
* ZEU Token Smart Contract Deployment (Devnet).

**Q2 2026: The Programmable Era**

* Full support for Solana Actions & Blinks.
* Mobile App Beta (iOS TestFlight / Android APK).
* Integration of ZK Compression for Mainnet account scaling.

**Q3 2026: The ZEU Economy**

* Token Generation Event (TGE) and Airdrop.
* Activation of "Staked Anti-Spam" filters.
* Developer SDK Release: "Build your own Email Plugin."

**Q4 2026: Enterprise & Expansion**

* **MulaMail Business:** Custom domain support (`@company.eth` or `@company.sol`) mapping.
* Fiat On-Ramp integration (Stripe) directly in the client.
* Cross-chain Bridge (Support for EVM-based Actions).

---

## 10. Conclusion

MulaMail 2.0 is not merely an upgrade to email; it is a **re-platforming of the internet's communication layer**. By replacing the centralized servers of Web2 with the cryptographic guarantees of Solana, and replacing static text with executable Blinks, we are unlocking a new economy.

In this new world, an email is a wallet, a message is a transaction, and identity is sovereign.

