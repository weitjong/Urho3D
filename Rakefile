# Usage: NOT intended to be used manually, it is designed to be triggered by Travis CI via GitHub web interface
desc 'Fetch and merge upstream urho3d/Urho3D to weitjong/Urho3D fork'
task :web_sync do
  ENV['TZ'] = 'Singapore'
  timestamp = Time.now.localtime
  system "git config user.name '#{ENV['GIT_NAME']}' && git config user.email '#{ENV['GIT_EMAIL']}' && git remote set-url --push origin https://#{ENV['GH_TOKEN']}@github.com/weitjong/Urho3D.git && git fetch origin master:master && git checkout master && git remote add upstream https://github.com/urho3d/Urho3D.git && git fetch upstream && git merge -m 'Web-sync at #{timestamp}.' upstream/master && git push -q -u origin master >/dev/null 2>&1 && git fetch origin master.OSX-CI:master.OSX-CI && git rebase master master.OSX-CI && git push -qf -u origin master.OSX-CI >/dev/null 2>&1"
end
