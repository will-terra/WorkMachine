module Sources
  class BackendBr < GithubIssues
    self.key = "backend_br"
    self.repo = "backend-br/vagas"

    private
      def relevant?(text) = ruby_or_rails?(text)
  end
end
