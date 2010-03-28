### Todomerang

Todomerang is a todo app that is built around context.

### Try it out

It's available at [http://todomerang.heroku.com](http://todomerang.heroku.com/).

### Deployment

To download the code and deploy on heroku, install the heroku gem and do:

    git clone git@github.com:erikpukinskis/todomerang.git
    cd todomerang
    heroku create --stack bamboo-mri-1.9.1
    git push heroku master

And you should be running on whatever url Heroku created for you. It would
probably be good to set a secret key for your sessions too:

    heroku config:add SESSION_SECRET="<put your own random stuff here>"
