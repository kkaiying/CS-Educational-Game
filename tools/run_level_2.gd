extends SceneTree

func _init():

    var maze := Level1.create_maze()
    var settings := Level1.create_settings()

    # fixed stickers
    maze.place_reward_sticker(Vector2i(1,0), settings)

    # robot, brain and trainer
    var robot := Robot.new()
    var agent := QAgent.new()
    var trainer := Trainer.new()
    trainer.maze = maze
    trainer.agent = agent
    trainer.robot = robot

    trainer.train(settings.episodes, settings.max_steps)

    agent.epsilon = 0
    var route: Array = trainer.run_one_episode(settings.max_steps)
    print(route)

    quit()