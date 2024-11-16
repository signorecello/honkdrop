# HonkDrop

This app didn't make it to the end of EthGlobal Bangkok, given how tired its author was after the best Devcon ever. Lol.

Anyway, here's what I have.

## Did I hear "Drop"? AirDrop?

That's right. But because you heard AirDrop doesn't mean you'll remain safe when claiming it.

This app allows you to claim an airdrop for which you're eligible using a stealth address (A.K.A. a fresh account, not connected to the eligible account).

Because you can use any kind of key, you can literally airdrop tokens to EthGlobal's participants wearing the Arx Wristband. You can send a payload, get the `secp256r1` signature, and verify that signature inside the circuit without revealing its wearer.

## Why is this such a big deal

You see, I built this in a day. But it took thousands of engineering hours to get here.

Totally worth it. You can use the same primitive to:

- create gated chatrooms without revealing identity
- provide privacy and safety to children by using the wristband as identifier/payment method
- of course airdrop tokens or POAPs to everyone that was present on a physical place without doxxing them
- increase whistleblower's privacy and safety
- you get the point by now

## What did you build on?

From the hackathon? Aaaaaa... Nothing I think. But I was meant to be using:

- Arx: for the wristbands, this is where I started figuring out the idea
- Stealthdrop: a famous app by 0xParc, which is NOT safe because ECDSA signatures are malleable and cannot be used as nullifiers
- PLUME nullifiers: a solution to the above problem, designed by @Divide-By-0 et al, and that prompted quite some development from Aztec Labs, Distributed Labs, and other engineers, in order to generate a good, fast Noir implementation
- Noir React Native: an amazing starter by @madztheo with a ton of primitives you can use to prove quickly on mobile phones using Noir
- Noir: duh
- EVM chains such as Gnosis (L1s) and Scroll (L2s), and I would also try the Bitcoin L2 despite being unsure if it could be deployed there (needs all the bn254 precompiles)

## What did you achieve?

I'm actually proud, heh. The hardest part is DONE, namely getting the circuit written, and its inputs.

I got stuck with React Native and XCode, and then it crashed with out of memory. I could certainly shave off a ton of gates on that circuit and make it work... but it's late, so late, and I'm so tired.

Next steps would be to have the app build, change the circuits to use the `secp256r1` curve, start experimenting with the Arx tooling to get a signature out of the smart card, write the actual airdrop contract and deploy it, and build some nice frontend.

Could I do it in a weekend, alone? Of course not. I was delusional.

## Now what

This is actually quite valuable for the Noir community so I'll keep building over the next weekend with the goal to show some interesting usage of PLUME nullifiers.

Will I be using this? Totally. Come on, I can airdrop POAPs to everyone wearing a wristband, how cool is that?
