// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IZKBattleship.sol";

contract ZKBattleship is IZKBattleship {
    
    /// MUTABLE FUNCTIONS ///
    
    function createGame(uint256 _board, bytes memory _proof) public override inactive() returns (uint256) {
        gameNonce++;
        Game storage game = games[gameNonce];
        gameLock[msg.sender] = gameNonce; // prevent address from multiple games
        game.participants.push(msg.sender);
        uuids[msg.sender][gameNonce] = 1; // encode game creator role
        
        
    }
    
    function joinGame(uint256 _room, bytes memory _board, bytes memory _proof) 
        public
        turn(_room)
        phaseRestrict(_room, Phase.Lobby)
        override {
        
    }
    
    function shoot(uint256 _room, uint8 _x, uint8 _y, bytes memory _prevRound)
        public
        validCoordinates(_x, _y)
        turn(_room)
        override {
        Game storage game = games[_room];
        if(game.firefight) {
            // verify previous shot's hit/miss (if not first round of shooting)
            (
                uint8 prevX,
                uint8 prevY,
                bool hit,
                bytes memory proof
            ) = abi.decode(_prevRound, (uint8, uint8, bool, bytes));
            uint8 by = uuids[msg.sender][_room] == 2 ? 0 : 1; // 0 or 1 creator/ joiner encoding
            bool proofEval = shotProof(game.boards[by], prevX, prevY, proof);
            require(proofEval, "Invalid shot proof");
            game.hits[by] += 1;
            emit ShotLanded(_room, prevX, prevY, game.participants[by], proof);
            // check if game is over
            if (isGameOver(_room)) {
                // end game and exit if exit condition
                gameOver(_room);
                return;
            }
        } else
            game.firefight = true;
        // fire a shot
        game.turn = !game.turn;
        emit ShotFired(_room, _x, _y, msg.sender);
    }
    
}